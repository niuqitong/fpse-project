open Core
open Collector
module P = Collector

type cpu_stats = P.cpu_stats
type memory_info = P.memory_info
type load_average_stats = P.load_average_stats
type process_count = P.process_count
type process_stats = P.process_stats

let clk_tck = 100.0

type cpu_usage_display = { cpu_id : string; cpu_usage_pct : float }

type process_stats_display = {
  pid : int;
  user : string;
  state : string;
  cpu_percentage : float;
  mem_percentage : float;
  command : string;
}

type calculator_output = {
  all_cpu_stats : cpu_usage_display list;
  memory_usage_gb : float * float;
  swap_usage_gb : float * float;
  load_avg : load_average_stats;
  process_cnt : process_count;
  proc_ls : process_stats_display list;
}

module Computer = struct
  let calculate_cpu_usage (stats_list : cpu_stats list) : cpu_usage_display list
      =
    List.map
      ~f:(fun stats ->
        let total_time =
          stats.user + stats.nice + stats.system + stats.idle + stats.iowait
          + stats.irq + stats.softirq
        in
        let non_idle_time = total_time - stats.idle in
        let cpu_usage_pct =
          100.0 *. float_of_int non_idle_time /. float_of_int total_time
        in

        { cpu_id = stats.cpu_id; cpu_usage_pct })
      stats_list

  let calculate_proc_cpu_percentage (utime : int) (stime : int)
      (start_time : int) (sys_uptime : float) : float =
    let total_time = float_of_int (utime + stime) in
    let uptime = sys_uptime *. clk_tck in
    let time_passed = uptime -. float_of_int start_time in
    total_time /. time_passed *. 100.0

  let calculate_proc_memory_percentage total_mem_kb vm_rss =
    let memory_usage = float_of_int vm_rss in
    memory_usage /. float_of_int total_mem_kb *. 100.0

  let calculate_process_list (total_mem_kb : int) (proc_ls : process_stats list)
      : process_stats_display list =
    List.map proc_ls ~f:(fun proc ->
        let cpu_p =
          calculate_proc_cpu_percentage proc.utime proc.stime proc.starttime
            proc.sys_uptime
        in
        let mem_p = calculate_proc_memory_percentage total_mem_kb proc.vm_rss in
        {
          pid = proc.pid;
          state = proc.state;
          cpu_percentage = cpu_p;
          mem_percentage = mem_p;
          command = proc.cmdline;
          user = proc.username;
        })

  let calculate_memory_usage (info : memory_info) : float * float =
    let kb_to_gb kb = float_of_int kb /. 1048576.0 in
    let used_memory_gb = kb_to_gb (info.mem_total - info.mem_free) in
    (used_memory_gb, kb_to_gb info.mem_total)

  let calculate_swap_usage (info : memory_info) : float * float =
    let kb_to_gb kb = float_of_int kb /. 1024.0 in
    let used_swap_gb = kb_to_gb (info.swap_total - info.swap_free) in
    (used_swap_gb, kb_to_gb info.swap_total)

  let calculate (cpu_stats_ls : cpu_stats list) (mem_info : memory_info)
      (load_avg_stats : load_average_stats) (proc_count : process_count)
      (proc_list : process_stats list) : calculator_output =
    {
      all_cpu_stats = calculate_cpu_usage cpu_stats_ls;
      memory_usage_gb = calculate_memory_usage mem_info;
      swap_usage_gb = calculate_swap_usage mem_info;
      load_avg = load_avg_stats;
      process_cnt = proc_count;
      proc_ls = calculate_process_list mem_info.mem_total proc_list;
    }
end

module Query = struct
  let compare_pid (a : process_stats_display) (b : process_stats_display) : int
      =
    compare a.pid b.pid

  let compare_user (a : process_stats_display) (b : process_stats_display) : int
      =
    String.compare a.user b.user

  let compare_state (a : process_stats_display) (b : process_stats_display) :
      int =
    String.compare a.state b.state

  let compare_cpu (a : process_stats_display) (b : process_stats_display) : int
      =
    Float.compare a.cpu_percentage b.cpu_percentage

  let compare_mem (a : process_stats_display) (b : process_stats_display) : int
      =
    Float.compare a.mem_percentage b.mem_percentage

  let order_by ?(cpu = false) ?(mem = false) ?(user = false) ?(pid = false)
      ?(state = false) ?(asc = false) (lst : process_stats_display list) :
      process_stats_display list =
    let comparator =
      match (cpu, mem, user, pid, state) with
      | true, _, _, _, _ -> compare_cpu
      | _, true, _, _, _ -> compare_mem
      | _, _, true, _, _ -> compare_user
      | _, _, _, true, _ -> compare_pid
      | _, _, _, _, true -> compare_state
      | _ -> failwith "No sorting criterion provided"
    in
    let sorted_list = List.sort ~compare:comparator lst in
    match asc with true -> sorted_list | false -> List.rev sorted_list

  let filter ?cpu_range ?mem_range ?state ?user
      (lst : process_stats_display list) : process_stats_display list =
    let cpu_check proc =
      match cpu_range with
      | Some (min, max) ->
          Float.compare proc.cpu_percentage min >= 0
          && Float.compare proc.cpu_percentage max <= 0
      | None -> true
    in
    let mem_check proc =
      match mem_range with
      | Some (min, max) ->
          Float.compare proc.mem_percentage min >= 0
          && Float.compare proc.mem_percentage max <= 0
      | None -> true
    in
    let state_check proc =
      match state with
      | Some s -> String.compare proc.state s = 0
      | None -> true
    in
    let user_check proc =
      match user with Some u -> String.compare proc.user u = 0 | None -> true
    in
    List.filter
      ~f:(fun proc ->
        cpu_check proc && mem_check proc && state_check proc && user_check proc)
      lst
end

[@@@coverage off]

module Printer = struct
  let ansi_fg_yellow = "\027[33m"
  let ansi_reset = "\027[0m"
  let ansi_bg_green = "\027[42m"
  let ansi_fg_light_blue = "\027[94m"
  let ansi_fg_light_green = "\027[92m"
  let ansi_fg_very_light_blue = "\027[38;5;117m"
  let clear_terminal () = Sys_unix.command "clear" |> ignore

  let print_bar usage (max_bars : int) =
    let bars_count = int_of_float (usage *. float_of_int max_bars /. 100.0) in
    let bars = String.init bars_count ~f:(fun _ -> '|') in
    let spaces = String.init (max_bars - bars_count) ~f:(fun _ -> ' ') in
    bars ^ spaces

  let print_calculator_output (output : calculator_output) =
    clear_terminal ();

    List.iter
      ~f:(fun cpu_stat ->
        Printf.printf "%s%s%s[%s%.4f%%]\n" ansi_fg_very_light_blue
          cpu_stat.cpu_id ansi_reset
          (print_bar cpu_stat.cpu_usage_pct 20)
          cpu_stat.cpu_usage_pct)
      output.all_cpu_stats;
    Printf.printf "\n";

    Printf.printf "%sTasks: %d%s, %s%d thr, %d kthr%s; %s%d running\n%s"
      ansi_fg_light_blue output.process_cnt.total_processes ansi_reset
      ansi_fg_light_green output.process_cnt.total_threads 0 ansi_reset
      ansi_fg_light_blue output.process_cnt.n_running_tasks ansi_reset;

    Printf.printf "%sLoad average: %.2f %.2f %.2f\n%s" ansi_fg_yellow
      output.load_avg.one_min_avg output.load_avg.five_min_avg
      output.load_avg.fifteen_min_avg ansi_reset;

    let used_memory_gb, total_memory_gb = output.memory_usage_gb in
    let memory_usage_pct = used_memory_gb /. total_memory_gb *. 100.0 in
    Printf.printf "%sMem%s[%s%.2fG/%.2fG%s] \n" ansi_fg_very_light_blue
      ansi_reset
      (ansi_fg_yellow ^ print_bar memory_usage_pct 40 ^ ansi_reset)
      used_memory_gb total_memory_gb ansi_reset;

    let used_swap_gb, total_swap_gb = output.swap_usage_gb in
    let swap_usage_pct = used_swap_gb /. total_swap_gb *. 100.0 in
    Printf.printf "%sSwp%s[%s%.2fM/%.2fM%s] \n" ansi_fg_very_light_blue
      ansi_reset
      (ansi_fg_yellow ^ print_bar swap_usage_pct 40 ^ ansi_reset)
      used_swap_gb total_swap_gb ansi_reset;

    Printf.printf "\n%s%6s %10s %4s %4s %7s %s%s\n" ansi_bg_green "PID" "USER"
      "CPU%" "MEM%" "STATE" "COMMAND" ansi_reset;

    List.iter output.proc_ls ~f:(fun proc ->
        Printf.printf "%6d %10s %4.1f %4.1f %7s %s\n" proc.pid proc.user
          proc.cpu_percentage proc.mem_percentage proc.state proc.command);
    Printf.printf "%!"
end
