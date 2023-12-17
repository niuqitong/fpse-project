[@@@warning "-32"]
open Core
open Collector
module P = Collector

type cpu_stats = P.cpu_stats
type memory_info = P.memory_info
type load_average_stats = P.load_average_stats
type process_count = P.process_count
type process_stats = P.process_stats

type cpu_usage_display = {
  cpu_id: string;
  cpu_usage_pct: float;
}
type process_stats_display = {
  pid: int;
  user: string;
  state: string;  (* e.g., "running", "sleeping", etc. *)
  cpu_percentage: float;
  mem_percentage: float;
  command: string;
}
type calculator_output = {
  all_cpu_stats: cpu_usage_display list;
  memory_usage_gb: float * float; (* (Used Memory, all memory) in GB *)
  swap_usage_gb: float * float; (* (Used swap, all Swap) in GB *)
  load_avg: load_average_stats;
  process_cnt: process_count;
  proc_ls: process_stats_display list;
}
module Computer = struct
  let calculate_cpu_usage (stats_list: cpu_stats list) : cpu_usage_display list =
    List.map ~f:(fun stats ->
      let total_time = stats.user + stats.nice + stats.system + stats.idle +
                      stats.iowait + stats.irq + stats.softirq in
      let non_idle_time = total_time - stats.idle in
      let cpu_usage_pct = 100.0 *. float_of_int non_idle_time /. float_of_int total_time in

      { cpu_id = stats.cpu_id; cpu_usage_pct }
    ) stats_list

  let calculate_cpu_percentage utime stime total_cpu_time =
    let total_time = float_of_int (utime + stime) in
    (total_time /. float_of_int total_cpu_time) *. 100.0

  let calculate_memory_percentage total_mem_kb vm_rss =
    let memory_usage = float_of_int vm_rss in
    (memory_usage /. (float_of_int total_mem_kb)) *. 100.0

  let calculate_process_list (total_mem_kb : int) (proc_ls: process_stats list) : process_stats_display list =
    List.map proc_ls ~f:(fun proc ->
      let cpu_p= calculate_cpu_percentage proc.utime proc.stime proc.total_cpu_time in
      let mem_p = calculate_memory_percentage total_mem_kb proc.vm_rss in
      {
        pid = proc.pid;
        state = proc.state;
        cpu_percentage = cpu_p;
        mem_percentage = mem_p;
        command = proc.cmdline;
        user = proc.username;
      })
    
  let calculate_memory_usage (info: memory_info) : (float * float) =
    let kb_to_gb kb = float_of_int kb /. 1048576.0 in
    let used_memory_gb = kb_to_gb (info.mem_total - info.mem_free) in
    (used_memory_gb, kb_to_gb info.mem_total)
  let calculate_swap_usage (info: memory_info) : (float * float) =
    let kb_to_gb kb = float_of_int kb /. 1048576.0 in
    let used_swap_gb = kb_to_gb (info.swap_total - info.swap_free) in
    (used_swap_gb, kb_to_gb info.swap_total)  
    
  let calculate (cpu_stats_ls: cpu_stats list) (mem_info: memory_info) 
                  (load_avg_stats: load_average_stats) (proc_count: process_count) (proc_list: process_stats list): calculator_output =
    {
      all_cpu_stats = calculate_cpu_usage cpu_stats_ls;
      memory_usage_gb = calculate_memory_usage mem_info;
      swap_usage_gb = calculate_swap_usage mem_info;
      load_avg = load_avg_stats;
      process_cnt = proc_count;
      proc_ls = calculate_process_list mem_info.mem_total proc_list
    }  
end

module Query = struct
  let compare_pid (a: process_stats_display) (b: process_stats_display) : int = 
    compare a.pid b.pid
  let compare_user a b = String.compare a.user b.user
  let compare_state a b = String.compare a.state b.state    
  let compare_cpu a b = Float.compare a.cpu_percentage b.cpu_percentage
  let compare_mem a b = Float.compare a.mem_percentage b.mem_percentage
  (* 
      user input               usage
      order by mem         ==> order_by ~mem:true process_list
      order by state asc   ==> order_by ~state:true ~asc:true process_list
      order by mem asc     ==> order_by ~mem:true ~asc:true process_list
  *)
  let order_by ?(cpu=false) ?(mem=false) ?(user=false) ?(pid=false) ?(state=false) ?(asc=false) (lst: process_stats_display list) : process_stats_display list =
    let comparator = match (cpu, mem, user, pid, state) with
      | (true, _, _, _, _) -> compare_cpu
      | (_, true, _, _, _) -> compare_mem
      | (_, _, true, _, _) -> compare_user
      | (_, _, _, true, _) -> compare_pid
      | (_, _, _, _, true) -> compare_state
      | _ -> failwith "No sorting criterion provided"
    in
    let sorted_list = List.sort ~compare:comparator lst in
    match asc with 
    | true -> sorted_list
    | false -> List.rev sorted_list

  (* 
      user input                usage
      select cpu > 0.5     ==>  filter ~cpu_range:(0.5, 100.0) process_list
      select mem < 10      ==>  filter ~mem_range:(0.0, 10.0) process_list
      select user = root   ==>  filter ~user:(Some "root")
      select state = sleep ==>  filter ~state:(Some "sleep")

  *)
  let filter ?cpu_range ?mem_range ?state ?user (lst: process_stats_display list) : process_stats_display list =
    let cpu_check proc =
      match cpu_range with
      | Some (min, max) -> Float.compare proc.cpu_percentage min >= 0 && 
                            Float.compare proc.cpu_percentage max <= 0
      | None -> true
    in
    let mem_check proc =
      match mem_range with
      | Some (min, max) -> Float.compare proc.mem_percentage min >= 0 && 
                            Float.compare proc.mem_percentage max <= 0
      | None -> true
    in
    let state_check proc =
      match state with
      | Some s -> (String.compare proc.state s) = 0
      | None -> true
    in
    let user_check proc =
      match user with
      | Some u -> (String.compare proc.user u) = 0
      | None -> true
    in
    List.filter ~f:(fun proc -> cpu_check proc && mem_check proc && state_check proc && user_check proc) lst

end
 

                                                      
module Printer = struct

  (* clear the terminal so the output put stays at the current window *)
  let clear_terminal () =
    Sys_unix.command "clear" |> ignore

  (* print some '|' to represent percentage *)
  let print_bar usage (max_bars : int) =
    let bars_count = int_of_float (usage *. float_of_int max_bars /. 100.0) in
    let bars = String.init bars_count ~f:(fun _ -> '|') in
    let spaces = String.init (max_bars - bars_count) ~f:(fun _ -> ' ') in
    bars ^ spaces  

  (* 
  output format

  0[||||||||        35.2%]  1[|||||||         29.9%]  
  2[|||||           19.7%]  3[|||             13.3%]  
  Tasks: 749, 2635 thr, 0 kthr; 4 running    
  Load average: 3.23 3.08 2.99  
  Mem[|||||||||||||||||                   10.2G/16.0G] 
  Swp[                                          0K/0K]  

  *) 
  let print_calculator_output (output: calculator_output) =
    clear_terminal ();
    
    List.iter ~f:(fun cpu_stat ->
      Printf.printf "%s[%s%.1f%%]  " cpu_stat.cpu_id (print_bar cpu_stat.cpu_usage_pct 20) cpu_stat.cpu_usage_pct
    ) output.all_cpu_stats;
    Printf.printf "\n";

    Printf.printf "Tasks: %d, %d thr, %d kthr; %d running\n"
      output.process_cnt.total_processes 
      output.process_cnt.total_threads
      0 
      output.process_cnt.n_running_tasks;

    Printf.printf "Load average: %.2f %.2f %.2f\n"
      output.load_avg.one_min_avg output.load_avg.five_min_avg output.load_avg.fifteen_min_avg;

    let (used_memory_gb, total_memory_gb) = output.memory_usage_gb in
    let memory_usage_pct = used_memory_gb /. total_memory_gb *. 100.0 in
    Printf.printf "Mem[%s%.1fG/%.1fG] \n" (print_bar memory_usage_pct 40) used_memory_gb total_memory_gb;

    let (used_swap_gb, total_swap_gb) = output.swap_usage_gb in
    let swap_usage_pct = used_swap_gb /. total_swap_gb *. 100.0 in
    Printf.printf "Swp[%s%.1fG/%.1fG] \n" (print_bar swap_usage_pct 40) used_swap_gb total_swap_gb;

    Printf.printf "\n%5s %10s %4s %4s %7s %s\n" "PID" "USER" "CPU%" "MEM%" "STATE" "COMMAND";
    
    let first_ten_procs = List.take output.proc_ls 10 in

    List.iter first_ten_procs ~f:(fun proc ->
      Printf.printf "%5d %10s %4.1f %4.1f %7s %s\n"
        proc.pid
        proc.user
        proc.cpu_percentage
        proc.mem_percentage
        proc.state
        proc.command
    );
  Printf.printf "%!"
end
  (* Core_unix.sleep 2; *)
