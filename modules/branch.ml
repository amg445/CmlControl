open Unix
open Universal

(****************************** Branch Module *********************************)
(******************************************************************************)

(* validate the branch name *)
let validate_branch (branch : string) : unit =
  if branch.[0] = '.' || branch.[0] = '-' then
    raise (Fatal "invalid branch name")
  else ()

(* returns a list of all branches in alphabetical order*)
let get_branches () : string list =
  let rec branch_loop acc q =
    match q with
    | []   -> acc
    | h::t -> begin
      let temp = ".cml/heads/"^h in
      if Sys.is_directory temp then
        let subs = temp |> Sys.readdir |> Array.to_list
        |> List.map (fun f -> h^"/"^f) in branch_loop acc t@subs
      else
        branch_loop (h::acc) t
    end
  in
  ".cml/heads" |> Sys.readdir |> Array.to_list |> branch_loop [] |>
  List.sort (Pervasives.compare)

(* returns string of name of the current branch *)
let get_current_branch () : string =
  try
    let ic = open_in ".cml/HEAD" in
    let raw = input_line ic in
    let _ = close_in ic in
    let split = (String.index raw '/') + 1 in
    String.sub raw split (String.length raw - split)
  with
    | Sys_error _ -> raise (Fatal "HEAD not found")
    | End_of_file -> raise (Fatal "HEAD not initialized")

(* returns the head ptr of the given branch *)
let get_branch_ptr (branch_name : string) : string =
  try
    let ic = open_in (".cml/heads/" ^ branch_name) in
    let ptr = input_line ic in
    close_in ic; ptr
  with
    | Sys_error _ -> raise (Fatal ("branch "^branch_name^" not found"))
    | End_of_file -> raise (Fatal (branch_name^" ptr not set"))

(* initializes a given commit to a given branch name *)
let set_branch_ptr (branch_name : string) (commit_hash : string) : unit =
  try
    let oc = open_out (".cml/heads/" ^ branch_name) in
    output_string oc commit_hash; close_out oc
  with
    | Sys_error _ -> raise (Fatal "write error")

(* recursively creates branch sub-directories as needed *)
let rec branch_help (path : string) (branch : string) : out_channel =
  try
    let slash = String.index branch '/' in
    let dir = String.sub branch 0 slash in
    let prefix = path^dir in
    if not (Sys.file_exists prefix) then mkdir prefix 0o777;
    (String.length branch - (slash+1)) |> String.sub branch (slash+1) |>
    branch_help (prefix^"/")
  with
  | Not_found -> open_out (path^"/"^branch)

(* create a new branch if it doesn't exist *)
let create_branch (branch : string) (ptr : string) : unit =
  if (get_branches () |> List.mem branch) then
    raise (Fatal ("a branch named "^branch^" already exists"))
  else
    let _ = validate_branch branch in
    let oc = begin
      if String.contains branch '/' then
        branch_help ".cml/heads/" branch
      else
        open_out (".cml/heads/"^branch)
    end in
    output_string oc ptr; close_out oc

(* delete a branch if it exists *)
let delete_branch (branch : string) : unit =
  if branch = get_current_branch () then
    raise (Fatal ("cannot delete branch '"^branch^"'"))
  else
    try
      if (get_branches () |> List.mem branch) then
        let _ = Sys.remove (".cml/heads/"^branch) in
        Print.print ("Deleted branch "^branch^"")
      else
        raise (Fatal ("branch '"^branch^"' not found"))
    with
    | Sys_error _ -> raise (Fatal "cannot perform such an operation")

(* switch current working branch *)
(* precondition: [branch] exists *)
let switch_branch (branch : string) (isdetached : bool) : unit =
  let cur = if isdetached then "" else get_current_branch () in
  if cur = branch then
    Print.print ("Already on branch '"^branch^"'")
  else
    let oc = open_out ".cml/HEAD" in
    output_string oc ("heads/"^branch); close_out oc;
    Print.print ("Switched to branch '"^branch^"'")
