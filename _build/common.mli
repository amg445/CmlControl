(* ($) is an infix operator for appending a char to a string *)
val ($): string -> char -> string

(* returns a pairs (d1,path) where [d1] is the first 2 chars of the hash
 * and [path] is the .cml/objects path of the hash *)
val split_hash: string -> string * string

(* returns (dir,file_name) for any string with the format "dir/fn" *)
val split_path: string -> string * string