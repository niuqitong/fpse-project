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


type process_stats = {
  pid: int;
  utime: int;
  stime: int;
  total_cpu_time: int;
  total_time: int;
  vm_rss: int;
  state: string;
  username: string;
  uid: int;
  cmdline: string;
};;

val read_cpu_stats : unit -> cpu_stats list
val read_memory_info : unit -> memory_info option
val read_load_average : unit -> load_average_stats option
val read_process_count : unit -> process_count
val read_process_stats : int -> process_stats
val list_pids : unit -> int list
val collect_process_stats : unit -> process_stats list