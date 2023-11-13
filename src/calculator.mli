(** The type representing structured CPU data *)
type cpu_info

(** The type representing structured memory data *)
type memory_info

(** The type representing structured process data *)
type process_info

(** Compute the CPU usage percentage *)
val calculate_cpu_usage : cpu_info -> float

(** Compute the memory usage percentage *)
val calculate_memory_usage : memory_info -> float

(** Process information on processes to compute relevant metrics *)
val process_processes : process_info list -> (int * float * float) list
(* Here, the returned list might contain tuples of process ID, CPU usage, and memory usage *)


