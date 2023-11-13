(** The type representing structured CPU data *)
type cpu_info

(** The type representing structured memory data *)
type memory_info

(** The type representing structured process data *)
type process_info

(** Parses raw CPU data into a structured format *)
val parse_cpu_info : string -> cpu_info

(** Parses raw memory data into a structured format *)
val parse_memory_info : string -> memory_info

(** Parses a list of raw process data into a list of structured format *)
val parse_process_info : string list -> process_info list
