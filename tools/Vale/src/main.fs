open Ast
open Ast_util
open Parse
open Parse_util
open TypeChecker
open Transform
open Emit_common_base
open Emit_common_top
open Microsoft.Dafny
open Microsoft.FSharp.Math
open Microsoft.FSharp.Text.Lexing
open DafnyInterface
open System.IO

let cur_file = ref ""
let lexbufOpt = ref (None:LexBuffer<byte> option)
let dafny_opts_rev = ref []

let main (argv) =
  let in_files_rev = ref ([]:(string * bool) list) in
  let includes_rev = ref ([]:string list) in
  let suffixMap_rev = ref ([]:(string * string) list) in
  let include_modules_rev = ref ([]:(string * string option option * (((loc * decl) * bool) list)) list)
  let all_fstar_type_files = ref ([]:string list) in
  let sourceDir = ref "." in
  let destDir = ref "." in
  let sourceFroms = ref (Map.empty:Map<id, string>)
  let destFroms = ref (Map.empty:Map<id, string>)
  let outfile = ref (None:string option) in
  let outfile_i = ref (None:string option) in
  let dafnyDirect = ref false in
  let emitFStarText = ref false in
  let arg_list = argv |> Array.toList in
  let debug_flags = ref (Set.empty:Set<string>) in
  let print_error_loc locOpt =
    match locOpt with
    | None -> eprintfn "\nerror:"
    | Some loc -> eprintfn "\nerror at %s:" (string_of_loc loc)
    in
  let print_error_prefix locOpt =
    match !lexbufOpt with
    | None -> eprintfn "\nerror processing file %s" !cur_file; print_error_loc locOpt
    | Some lexbuf -> eprintfn "\nerror at line %i column %i of file %s" (line lexbuf) (col lexbuf) (file lexbuf)
    in
  let rec print_error locOpt e =
    match e with
    | (LocErr (loc, e)) as x ->
        if Set.contains "stack" !debug_flags then eprintfn ""; eprintfn "internal details:"; print_error_loc locOpt; eprintfn "%s" (x.ToString ())
        print_error (Some loc) e
    | (Err s) as x ->
        print_error_loc locOpt;
        eprintfn "%s" s;
        if Set.contains "stack" !debug_flags then eprintfn ""; eprintfn "internal details:"; eprintfn "%s" (x.ToString ());
        exit 1
    | (UnsupportedErr (s, loc, msg)) as x ->
        print_error_loc locOpt;
        eprintfn "%s" s;
        eprintfn "  (see %s for location of unsupported declaration)" (string_of_loc loc);
        (match msg with None -> () | Some s-> eprintfn "  reason for unsupported declaration: %s" s);
        exit 1
    | (InternalErr s) as x ->
        print_error_loc locOpt
        eprintfn "internal error:"
        eprintfn "%s" s
        eprintfn "\ninternal details:"
        eprintfn "%s" (x.ToString ())
        exit 1
    | ParseErr x -> (print_error_prefix locOpt; eprintfn "%s" x; exit 1)
    | :? System.ArgumentException as x -> (print_error_prefix locOpt; eprintfn "%s" (x.ToString ()); exit 1)
    | Failure x -> (print_error_prefix locOpt; eprintfn "%s" x; exit 1)
    | x -> (print_error_loc locOpt; eprintfn "%s" (x.ToString ()); exit 1)
    in
  try
  (
    let parse_argv (args:string list) =
      let rec match_args (arg_list:string list) =
        match arg_list with
        | "-dafnyDirect" ::l ->
            if !emitFStarText
            then failwith "Cannot include include both -dafnyDirect and -fstarText"
            else dafnyDirect := true; match_args l
        | "-h" :: [] -> failwith "TODO: Implement command line help"
        | "-dafnyText" :: l ->
            if !dafnyDirect
            then failwith "Cannot include include both -dafnyDirect and -dafnyText"
            else match_args l
        | "-fstarText" :: l ->
            if !dafnyDirect
            then failwith "Cannot include include both -dafnyDirect and -fstarText"
            else emitFStarText := true; match_args l
        | "-i" :: l ->
          match l with
          | [] -> failwith "Specify include file"
          | f :: l -> includes_rev := f::(!includes_rev); match_args l
        | "-include" :: l ->
          match l with
          | [] -> failwith "Specify include file"
          | f :: l -> in_files_rev := (f, false)::(!in_files_rev); match_args l
        | "-sourceDir" :: l ->
          match l with
          | x :: l -> sourceDir := x; match_args l
          | _ -> failwith "Specify source directory (to be prepended to -in files)"
        | "-destDir" :: l ->
          match l with
          | x :: l -> destDir := x; match_args l
          | _ -> failwith "Specify destination directory (to be prepended to -out file)"
        | "-sourceFrom" :: l ->
          match l with
          | x :: y :: l -> sourceFroms := Map.add (Id x) y !sourceFroms; match_args l
          | _ -> failwith "Specify identifier and path"
        | "-destFrom" :: l ->
          match l with
          | x :: y :: l -> destFroms := Map.add (Id x) y !destFroms; match_args l
          | _ -> failwith "Specify identifier and path"
        | "-includeSuffix" :: l ->
          match l with
          | src :: dst :: l -> suffixMap_rev := (src, dst)::(!suffixMap_rev); match_args l
          | _ -> failwith "Specify include suffix mapping"
        | "-in" :: l ->
          match l with
          | [] -> failwith "Specify input file"
          | f :: l -> in_files_rev := (f, true)::!in_files_rev; match_args l
        | "-out" :: l ->
          match l with
          | [] -> failwith "Specify output file"
          | f :: l -> outfile := Some f; match_args l
        | "-outi" :: l ->
          match l with
          | [] -> failwith "Specify output interface file"
          | f :: l -> outfile_i := Some f; match_args l
        | "-debug" :: l ->
          match l with
          | [] -> failwith "Specify debug feature name"
          | x :: l -> debug_flags := Set.add x !debug_flags; match_args l
        | "-break" :: l -> ignore (System.Diagnostics.Debugger.Launch()); match_args l
        | "-codeOnly" :: l -> global_code_only := true; match_args l
        | "-reprint" :: file :: l -> reprint_file := Some file; match_args l
        | "-reprintVerbatims=false" :: l -> reprint_verbatims := false; match_args l
        | "-reprintGhostDecls=false" :: l -> reprint_ghost_decls := false; match_args l
        | "-reprintSpecs=false" :: l -> reprint_specs := false; match_args l
        | "-reprintGhostStmts=false" :: l -> reprint_ghost_stmts := false; match_args l
        | "-reprintLoopInvs=false" :: l -> reprint_loop_invs := false; match_args l
        | "-reprintBlankLines=false" :: l -> reprint_blank_lines := false; match_args l
        | "-noLemmas" :: l -> no_lemmas := true ; match_args l
        | "-typecheck" :: l -> do_typecheck := true; match_args l
        | "-typecheck=false" :: l -> do_typecheck := false; match_args l
        | f :: l ->
          if f.[0] = '-' then
            failwith ("Unrecognized argument: " + f + "\n")
          elif f.StartsWith "/" then
            dafny_opts_rev := f::(!dafny_opts_rev); match_args l
          else
            failwith ("Unrecognized argument: " + f + "\n")
        | [] -> if List.length !in_files_rev = 0 then failwith "Use -in to specify input file"
        in
        match_args args
      in
    parse_argv (List.tail arg_list);
    let in_files = List.rev (!in_files_rev) in
    let flagsSuffixMap = List.rev !suffixMap_rev in
    let debugIncludes = Set.contains "includes" !debug_flags in
    let parse_file comment name =
      //printfn "%sparsing %s" comment name
      cur_file := name
      let stream_in = System.IO.File.OpenRead(name) in
      let parse_in = new System.IO.BinaryReader(stream_in) in
      let lexbuf = LexBuffer<byte>.FromBinaryReader parse_in in
      setInitialPos lexbuf name
      lexbufOpt := Some lexbuf;
      Lex.init_lex ();
      let p = Parse.start Lex.lextoken lexbuf in
      lexbufOpt := None;
      parse_in.Close ()
      stream_in.Close ()
      p
    let includesSet = Set.ofList (List.map Path.GetFullPath !includes_rev) in
    let processedFiles = ref includesSet in
    let rebaseFile (o:string) (xabs:string):string =
      // Attempt to build a relative path to xabs from o; if that fails, use an absolute path
      let oabs = Path.GetFullPath o in
      let rec commonPrefix (s1:string) (s2:string) (i:int) (k:int) =
        if i >= s1.Length || i >= s2.Length then k else
        if s1.[i] <> s2.[i] then k else
        commonPrefix s1 s2 (i + 1) (if s1.[i] = Path.DirectorySeparatorChar then (i + 1) else k)
        in
      let prefixLen = commonPrefix oabs xabs 0 0 in
      let suffix1 = oabs.Substring(prefixLen) in
      let suffix2 = xabs.Substring(prefixLen) in
      let flipSeparator c = if c = Path.DirectorySeparatorChar then [".."] else [] in
      let flips = List.collect flipSeparator (List.ofArray (suffix1.ToCharArray ())) in
      let relPath = Path.Combine (List.toArray (flips @ [suffix2])) in
      // If the relative path is equivalent to the absolute path, use the relative path:
      let resultPath () = Path.GetFullPath (Path.Combine (Path.GetDirectoryName o, relPath)) in
      (if debugIncludes then
        printfn "rebase file:";
        printfn "   from: %A" o;
        printfn "     to: %A" xabs;
        printfn "  guess: %A" relPath;
        (try (let p = resultPath () in printfn "%s: %A" (if p = xabs then "     ok" else " failed") p) with err -> printfn "  error: %A" err)
      );
      let relPathOk = try (resultPath () = xabs) with _ -> false in
      if relPathOk then relPath else xabs
      in
    let processSuffixInclude (isFrom:bool) (includerDirRaw:bool -> string) (x:string):unit =
      let x =
        if !dafnyDirect then
          if isFrom then
            Path.GetFullPath (Path.Combine (includerDirRaw true, x))
          else
            Path.GetFullPath (Path.Combine (!destDir, includerDirRaw true, x))
        else
          if isFrom then
            let xabs = Path.GetFullPath (Path.Combine (includerDirRaw true, x)) in
            match !outfile with
            | None -> xabs
            | Some o -> rebaseFile o xabs
          else
            x
        in
      (if debugIncludes then printfn "adding generated include to %A" x);
      includes_rev := x::!includes_rev
      in
    let processVerbatimInclude (sourceDir:string) (x:string):unit =
      let xabs = Path.GetFullPath (Path.Combine (sourceDir, x)) in
      if not (Set.contains xabs !processedFiles) then
        processedFiles := Set.add xabs !processedFiles;
        let path =
          match !outfile with
          | None -> xabs
          | Some o -> rebaseFile o xabs
          in
        (if debugIncludes then printfn "adding include from %A: %A --> %A --> %A" sourceDir x xabs path);
        includes_rev := path::!includes_rev
      in
    let rec processFStarInclude (x:string) (opened:string option option):unit =
(*
      if !all_fstar_type_files = [] then 
        all_fstar_type_files := Directory.EnumerateFiles(".", "*.fst.types.vaf", SearchOption.AllDirectories) |> List.ofSeq
      let filename = x + ".fst.types.vaf" in
      let f = List.tryFind (fun f -> (Path.GetFileName f) = filename) !all_fstar_type_files in
      let ds = 
        match f with
        | Some f -> 
          if not (Set.contains f !processedFiles) then
            processedFiles := Set.add f !processedFiles;
            processFile (f, false)
          else []
        | _ -> if !do_typecheck then err (sprintf "cannot find exported fstar type file %s" filename) else []
      in
      include_modules_rev := (x, opened, ds)::!include_modules_rev;
*)
      include_modules_rev := (x, opened, [])::!include_modules_rev;
      ()
    and processFile (xRaw:string, isInputFile:bool):((loc * decl) * bool) list =
      let x = if isInputFile then Path.Combine (!sourceDir, xRaw) else xRaw in
      (if debugIncludes then printfn "processing file %A" x);
      let xabs = Path.GetFullPath x in
      if Set.contains xabs !processedFiles then [] else
      processedFiles := Set.add xabs !processedFiles;
      let (incs, ds) = parse_file "// " x in
      let ds = List.map (fun d -> (d, isInputFile)) ds in
      let processInclude {inc_loc = loc; inc_attrs = attrs; inc_path = incPath} =
        try
          let attrs = skip_locs_attrs attrs in
          let from_opt = attrs_get_id_opt (Id "from") attrs in
          let incBaseRaw (isDest:bool):string =
            let froms = if isDest then !destFroms else !sourceFroms in
            match from_opt with
            | None -> Path.GetDirectoryName xRaw
            | Some p when Map.containsKey p froms -> Map.find p froms
            | Some p -> err ("directory for " + (err_id p) + " not specified; use -" + (if isDest then "destFrom " else "sourceFrom ") + (err_id p) + " <path> command line option to specify")
            in
          let incBase (isDest:bool):string = Path.Combine (!sourceDir, incBaseRaw isDest) in
          if attrs_get_bool (Id "verbatim") false attrs then
            (if isInputFile then processVerbatimInclude (incBase false) incPath);
            []
          else if attrs_get_bool (Id "fstar") false attrs then
            let opened =
              match attrs_get_exps_opt (Id "open") attrs with
              | None -> None
              | Some [EVar (Id x, _) | ELoc (_, EVar (Id x, _))] -> Some (Some x)
              | Some _ -> Some None
            processFStarInclude incPath opened;
            []
          else
            let suffixMap = List.collect (fun a ->
              match a with (Id "suffix", [EString s1; EString s2]) -> [(s1, s2)] | _ -> []) attrs in
            let suffixMap = flagsSuffixMap @ suffixMap in
            let suffixFalse = List.exists (fun a ->
              match a with (Id "suffix", [EBool false]) -> true | _ -> false) attrs in
            let useSuffix = match suffixMap with [] -> false | _::_ -> isInputFile && not suffixFalse in
            let rec resuffix map s =
              match map with
              | [] -> err ("could not find matching suffix for path \"" + s + "; use 'include{:suffix false} to suppress this feature")
              | (s1, s2)::t when (let s1: string = s1 in s.EndsWith(s1)) -> s.Substring(0, s.Length - s1.Length) + s2
              | _::t -> resuffix t s
              in
            (if useSuffix then processSuffixInclude (Option.isSome from_opt) incBaseRaw (resuffix suffixMap incPath));
            processFile (Path.Combine (incBase false, incPath), false)
        with err -> raise (LocErr (loc, err))
        in
      (List.collect processInclude incs) @ ds
      in
    let ins = List.map processFile in_files in
    let decls = List.concat ins in
    let ms = new MemoryStream() in
    let stream =
      match !outfile with
      | None -> System.Console.Out
      | Some s -> (new System.IO.StreamWriter(ms)):>System.IO.TextWriter
      in
    let ms_i = new MemoryStream() in
    let stream_i =
      match !outfile_i with
      | None -> None
      | Some s -> Some ((new System.IO.StreamWriter(ms_i)):>System.IO.TextWriter)
      in
    let ps_i =
      match stream_i with
      | None -> None
      | Some s ->
          Some {
            print_out = s;
            print_interface = None;
            cur_loc = ref { loc_file = ""; loc_line = 1; loc_col = 1; loc_pos = 0 };
            cur_indent = ref "";
          }
      in
    let ps =
      {
        print_out = stream;
        print_interface = ps_i;
        cur_loc = ref { loc_file = ""; loc_line = 1; loc_col = 1; loc_pos = 0 };
        cur_indent = ref "";
      } in
    let write_streams () =
      let write_to_file filename (stream:TextWriter) (ms:MemoryStream) =
        stream.Flush();
        match filename with
        | None -> ()
        | Some s ->
          let s = Path.Combine (!destDir, s) in
          let _ = System.IO.Directory.CreateDirectory (System.IO.Path.GetDirectoryName s) in
          let s = new System.IO.FileStream(s, System.IO.FileMode.Create) in
          ms.WriteTo(s);
          s.Close()
        in
      write_to_file !outfile stream ms;
      match stream_i with
      | None -> ()
      | Some s ->
        write_to_file !outfile_i s ms_i
      in
    let close_streams () =
      (match stream_i with None -> () | Some s -> s.Close());
      stream.Close ()
      in
    try
    (
      if (not !dafnyDirect) then List.iter (fun (s:string) -> ps.PrintLine ("include \"" + s.Replace("\\", "\\\\") + "\"")) (List.rev !includes_rev);
      precise_opaque := !emitFStarText;
      fstar := !emitFStarText;
      let include_modules = List.rev (!include_modules_rev) in
      let decls = build_decls empty_env include_modules decls in
      (match !reprint_file with
        | None -> ()
        | Some filename ->
            let rstream = (new System.IO.StreamWriter(new System.IO.FileStream(filename, System.IO.FileMode.Create))):>System.IO.TextWriter in
            let rps =
              {
                print_out = rstream;
                print_interface = None;
                cur_loc = ref { loc_file = ""; loc_line = 1; loc_col = 1; loc_pos = 0 };
                cur_indent = ref "";
              } in
            Emit_vale_text.emit_decls rps (List.rev (!reprint_decls_rev));
            rstream.Close ()
        );
      if !emitFStarText then
        Emit_fstar_text.emit_decls ps decls (List.map (fun (x, b, d) -> (x, b)) include_modules)
      else
        if !dafnyDirect then
          // Initialize Dafny objects
          let mdl = new LiteralModuleDecl(new DefaultModuleDecl(), null) in
          let built_ins = new BuiltIns() in
          let arg_list = List.rev (!cur_file::!dafny_opts_rev) in
          DafnyOptions.Install(new DafnyOptions(new ConsoleErrorReporter()));
          Emit_dafny_direct.build_dafny_program mdl built_ins (List.rev !includes_rev) decls;
          DafnyDriver.Start_Dafny(List.toArray arg_list, mdl, built_ins) |> ignore
        else Emit_dafny_text.emit_decls ps decls;
      write_streams ();
      close_streams ()
    ) with err -> close_streams (); raise err
  )
  with err -> print_error None err
;;

let () = main (System.Environment.GetCommandLineArgs ())

