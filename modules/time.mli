(******************************* Time Module **********************************)
(******************************************************************************)

(* returns a timestamp in the format [hr:min:sec] *)
val time: int -> int -> int -> string

(* returns the day of the week abbreviation *)
val day: int -> string

(* returns the month abbreviation *)
val month: int -> string

(* returns the current year *)
val year: int -> string

(* returns a formatted timestamp string for cml commits *)
val get_time: Unix.tm -> string
