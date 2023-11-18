(** Type definitions *)
type cpu_info
type mem_info
type process_info

(** Collects raw CPU data from /proc/stat 
  * @return cpu_info type containing raw CPU data 
  *)
val collect_cpu_info : unit -> cpu_info Lwt.t

(** Collects raw memory data from /proc/meminfo 
  * @return mem_info type containing raw memory data
  *)
val collect_memory_info : unit -> mem_info Lwt.t

(** Collects raw process information for a given PID from /proc/[pid]/stat 
  * @param pid Process ID for which information is to be collected
  * @return process_info type containing raw process data
  *)
val collect_process_info : pid:int -> process_info Lwt.t

(** Collects raw process information for all processes from /proc 
  * @return List of process_info type containing raw data for all processes
  *)
val collect_all_process_info : unit -> process_info list Lwt.t
