type cpu_stats = {
  cpu_id : string;
  user : int;
  nice : int;
  system : int;
  idle : int;
  iowait : int;
  irq : int;
  softirq : int;
}

type memory_info = {
  mem_total: int;  (* in Kilobytes *)
  mem_free: int;   (* in Kilobytes *)
  swap_total: int; (* in Kilobytes *)
  swap_free: int;  (* in Kilobytes *)
}


type load_average_stats = {
  one_min_avg : float;
  five_min_avg : float;
  fifteen_min_avg : float;
}

type process_count = {
  total_processes: int;
  total_threads: int;
  n_running_tasks: int;
} 

type calculator_output = {
    cpu_id: string;
    cpu_usage_pct: float;
    memory_usage_gb: float * float; (* (Used Memory, Used Swap) in GB *)
    load_avg: load_average_stats;
    process_stats: process_count;
}

val calculate_cpu_usage : cpu_stats -> float
val calculate_memory_usage : memory_info -> (float * float)
val calculate : cpu_stats -> memory_info -> load_average_stats -> process_count -> calculator_output
val print_calculator_output : calculator_output -> unit
