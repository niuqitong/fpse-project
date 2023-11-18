(** The type representing structured CPU data *)
type cpu_info

(** The type representing structured memory data *)
type memory_info

(** The type representing structured process data *)
type process_info

(** The type representing structured process data that’s human readable and intuitive *)
type process_info_readable

(** Compute the CPU usage percentage 
   * @param cpu_info: type containing structured CPU running statistics 
   * @return float: CPU usage percentage 
*)
val calculate_cpu_usage : cpu_info -> float

(** Compute the memory usage percentage 
   * @param memory_info: type containing structured CPU memory statistics 
   * @return float: memory usage percentage 
*)
val calculate_memory_usage : memory_info -> float

(** Process information on processes to compute relevant metrics 
   * @param process_info: list of structured data containing process information 
   * @return process_info_readable list: list of structured info  of process containing  PID, CPU usage, memory usage, status, command, etc. 
*)
val process_processes : process_info list -> process_info_readable list
