open Core
open Collector
module P = Collector

type cpu_stats = P.cpu_stats
type memory_info = P.memory_info
type load_average_stats = P.load_average_stats
type process_count = P.process_count

(*
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
*)

type calculator_output = {
    cpu_id: string;
    cpu_usage_pct: float;
    memory_usage_gb: float * float; (* (Used Memory, Used Swap) in GB *)
    load_avg: load_average_stats;
    process_stats: process_count;
}
let calculate_cpu_usage (stats: cpu_stats) : float =
  let total_time = stats.user + stats.nice + stats.system + stats.idle +
                   stats.iowait + stats.irq + stats.softirq in
  let non_idle_time = total_time - stats.idle in
  100.0 *. float_of_int non_idle_time /. float_of_int total_time

let calculate_memory_usage (info: memory_info) : (float * float) =
  let kb_to_gb kb = float_of_int kb /. 1048576.0 in
  let used_memory_gb = kb_to_gb (info.mem_total - info.mem_free) in
  let used_swap_gb = kb_to_gb (info.swap_total - info.swap_free) in
  (used_memory_gb, used_swap_gb)
  
  
let calculate (cpu_stats: cpu_stats) (mem_info: memory_info) 
                (load_avg_stats: load_average_stats) (proc_count: process_count) : calculator_output =
  {
    cpu_id = cpu_stats.cpu_id;
    cpu_usage_pct = calculate_cpu_usage cpu_stats;
    memory_usage_gb = calculate_memory_usage mem_info;
    load_avg = load_avg_stats;
    process_stats = proc_count;
  }

let print_calculator_output (output: calculator_output) =
  let (used_memory_gb, used_swap_gb) = output.memory_usage_gb in
  Printf.printf "CPU id: %s\n" output.cpu_id;

  Printf.printf "CPU Usage: %.2f%%\n" output.cpu_usage_pct;
  Printf.printf "Memory Usage: %.2f GB\n" used_memory_gb;
  Printf.printf "Swap Usage: %.2f GB\n" used_swap_gb;
  Printf.printf "Load Average: %.2f, %.2f, %.2f\n"
    output.load_avg.one_min_avg output.load_avg.five_min_avg output.load_avg.fifteen_min_avg;
  Printf.printf "Total Processes: %d\n" output.process_stats.total_processes;
  Printf.printf "Total Threads: %d\n" output.process_stats.total_threads;
  Printf.printf "Running Tasks: %d\n" output.process_stats.n_running_tasks
    
