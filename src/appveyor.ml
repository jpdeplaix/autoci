let to_yaml config : Yaml.yaml =
  let open Yaml in
  let no_anchor s = {anchor = None; value = s} in
  let yaml_array ~name items = no_anchor name, `A (List.map (fun p -> `String (no_anchor p)) items) in
  let yaml_assoc_list = List.map (fun (name, value) -> (no_anchor name, `String (no_anchor value))) in
  let platforms = [ "x86" ] in
  let install = [
    ("ps", "iex ((new-object net.webclient).DownloadString(\"https://raw.githubusercontent.com/$env:FORK_USER/ocaml-ci-scripts/$env:FORK_BRANCH/appveyor-install.ps1\"))");
  ] in
  let build_script = [
    "call %CYG_ROOT%\\bin\\bash.exe -l %APPVEYOR_BUILD_FOLDER%\\appveyor-opam.sh"
  ] in
  let custom_globals = match Test.(str_of_pins config.pins) with
    | None -> Test.(test_info_to_assoc_list config.globals)
    | Some pins -> ("PINS", pins)::Test.(test_info_to_assoc_list config.globals)
  in
  let yaml_globals = no_anchor "global", `O (yaml_assoc_list @@
                                             ("FORK_USER", "ocaml")::
                                             ("FORK_BRANCH", "master")::
                                             ("CYG_ROOT", "C:\\cygwin64")::
                                             custom_globals)
  in
  let test_list : yaml = `A List.(map (fun test ->
      `O (yaml_assoc_list @@ Test.test_info_to_assoc_list test))
      config.tests)
  in
  let yaml_matrix = no_anchor "matrix", test_list in
  `O [ yaml_array ~name:"platform" platforms;
       no_anchor "environment", `O [yaml_globals; yaml_matrix];
       no_anchor "install", `A [`O (yaml_assoc_list install)];
       yaml_array ~name:"build_script" build_script;
     ]
