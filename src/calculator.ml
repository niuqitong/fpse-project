open Core
open Collector
module P = Collector

type cpu_usage_display = {
  cpu_id: string;
  cpu_usage_pct: float;
}

type cpu_stats = P.cpu_stats
type memory_info = P.memory_info
type load_average_stats = P.load_average_stats
type process_count = P.process_count

type calculator_output = {
    all_cpu_stats: cpu_usage_display list;
    memory_usage_gb: float * float; (* (Used Memory, all memory) in GB *)
    swap_usage_gb: float * float; (* (Used swap, all Swap) in GB *)
    load_avg: load_average_stats;
    process_stats: process_count;
}
let calculate_cpu_usage (stats_list: cpu_stats list) : cpu_usage_display list =
  List.map ~f:(fun stats ->
    let total_time = stats.user + stats.nice + stats.system + stats.idle +
                     stats.iowait + stats.irq + stats.softirq in
    let non_idle_time = total_time - stats.idle in
    let cpu_usage_pct = 100.0 *. float_of_int non_idle_time /. float_of_int total_time in

    { cpu_id = stats.cpu_id; cpu_usage_pct }
  ) stats_list


let calculate_memory_usage (info: memory_info) : (float * float) =
  let kb_to_gb kb = float_of_int kb /. 1048576.0 in
  let used_memory_gb = kb_to_gb (info.mem_total - info.mem_free) in
  (used_memory_gb, kb_to_gb info.mem_total)
let calculate_swap_usage (info: memory_info) : (float * float) =
  let kb_to_gb kb = float_of_int kb /. 1048576.0 in
  let used_swap_gb = kb_to_gb (info.swap_total - info.swap_free) in
  (used_swap_gb, kb_to_gb info.swap_total)  
  
let calculate (cpu_stats_ls: cpu_stats list) (mem_info: memory_info) 
                (load_avg_stats: load_average_stats) (proc_count: process_count) : calculator_output =
  {
    (* cpu_id = cpu_stats.cpu_id; *)
    all_cpu_stats = calculate_cpu_usage cpu_stats_ls;
    memory_usage_gb = calculate_memory_usage mem_info;
    swap_usage_gb = calculate_swap_usage mem_info;
    load_avg = load_avg_stats;
    process_stats = proc_count;
  }

 
(* 
output format

0[||||||||        35.2%]  1[|||||||         29.9%]  
2[|||||           19.7%]  3[|||             13.3%]  
Tasks: 749, 2635 thr, 0 kthr; 4 running    
Load average: 3.23 3.08 2.99  
Mem[|||||||||||||||||                   17.7G/36.0G] 
Swp[                                          0K/0K]  

*)
                                                      
(* clear the terminal so the output put stays at the current window *)
let clear_terminal () =
  Sys_unix.command "clear" |> ignore

(* print some '|' to represent percentage *)
let print_bar usage (max_bars : int) =
  let bars_count = int_of_float (usage *. float_of_int max_bars /. 100.0) in
  let bars = String.init bars_count ~f:(fun _ -> '|') in
  let spaces = String.init (max_bars - bars_count) ~f:(fun _ -> ' ') in
  bars ^ spaces  

let print_calculator_output (output: calculator_output) =
  clear_terminal ();
  
  List.iter ~f:(fun cpu_stat ->
    Printf.printf "%s[%s%.1f%%]  " cpu_stat.cpu_id (print_bar cpu_stat.cpu_usage_pct 20) cpu_stat.cpu_usage_pct
  ) output.all_cpu_stats;
  Printf.printf "\n";

  Printf.printf "Tasks: %d, %d thr, %d kthr; %d running\n"
    output.process_stats.total_processes 
    output.process_stats.total_threads
    0 
    output.process_stats.n_running_tasks;

  Printf.printf "Load average: %.2f %.2f %.2f\n"
    output.load_avg.one_min_avg output.load_avg.five_min_avg output.load_avg.fifteen_min_avg;

  let (used_memory_gb, total_memory_gb) = output.memory_usage_gb in
  let memory_usage_pct = used_memory_gb /. total_memory_gb *. 100.0 in
  Printf.printf "Mem[%s%.1fG/%.1fG] \n" (print_bar memory_usage_pct 40) used_memory_gb total_memory_gb;

  let (used_swap_gb, total_swap_gb) = output.swap_usage_gb in
  let swap_usage_pct = used_swap_gb /. total_swap_gb *. 100.0 in
  Printf.printf "Swp[%s%.1fG/%.1fG] \n" (print_bar swap_usage_pct 40) used_swap_gb total_swap_gb

  (* Core_unix.sleep 2; *)