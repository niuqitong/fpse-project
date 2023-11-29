type cpu_stats = {
  cpu_id : string;
  user : int;
  nice : int;
  system : int;
  idle : int;
  iowait : int;
  irq : int;
  softirq : int;
};;

type memory_info = {
  mem_total: int;  (* in Kilobytes *)
  mem_free: int;   (* in Kilobytes *)
  swap_total: int; (* in Kilobytes *)
  swap_free: int;  (* in Kilobytes *)
};;

type load_average_stats = {
  one_min_avg : float;
  five_min_avg : float;
  fifteen_min_avg : float;
};;

type process_count = {
  total_processes: int;
  total_threads: int;
  n_running_tasks: int;
};;

val read_cpu_stats : unit -> cpu_stats list
val read_memory_info : unit -> memory_info option
val read_load_average : unit -> load_average_stats option
val read_process_count : unit -> process_count