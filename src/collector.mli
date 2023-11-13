(** Collects raw CPU data from /proc/stat *)
val collect_cpu_info : unit -> string

(** Collects raw memory data from /proc/meminfo *)
val collect_memory_info : unit -> string

(** Collects raw process information from /proc/[pid]/stat for all PIDs *)
val collect_process_info : unit -> string list
