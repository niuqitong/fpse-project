open Batteries

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
  mem_total: int;  
  mem_free: int;   
  swap_total: int; 
  swap_free: int;  
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
  vm_rss: int;
  uid: int;
  cmdline: string;
};;

let parse_cpu_stats_line line =
  let parts = String.split_on_char ' ' line
              |> List.filter (fun s -> s <> "") in
  match parts with
  | cpu_id :: user :: nice :: system :: idle :: iowait :: irq :: softirq :: _ ->
    Some {
      cpu_id;
      user = int_of_string user;
      nice = int_of_string nice;
      system = int_of_string system;
      idle = int_of_string idle;
      iowait = int_of_string iowait;
      irq = int_of_string irq;
      softirq = int_of_string softirq;
    }
  | _ -> None

let read_cpu_stats () : cpu_stats list =
  let lines = List.of_enum (File.lines_of "/proc/stat") in
  List.fold_left (fun acc line ->
    if String.starts_with line "cpu" && not (String.equal line "cpu") then
      match parse_cpu_stats_line line with
      | Some stats -> stats :: acc
      | None -> acc
    else acc
  ) [] lines

let read_memory_info () : memory_info option =
  let meminfo = File.lines_of "/proc/meminfo" in
  let parse_line line =
    match String.split_on_char ':' line with
    | [key; value] ->
      let value = String.trim value |> String.split_on_char ' ' |> List.hd in
      begin
        try Some (String.trim key, int_of_string value)
        with Failure _ -> None
      end
    | _ -> None
  in
  let meminfo_list = Enum.filter_map parse_line meminfo |> List.of_enum in
  try
    let find_value key = List.assoc key meminfo_list in
    Some {
      mem_total = find_value "MemTotal";
      mem_free = find_value "MemFree";
      swap_total = find_value "SwapTotal";
      swap_free = find_value "SwapFree";
    }
  with Not_found -> None

let read_load_average () : load_average_stats option =
  try
    let line = input_line (open_in "/proc/loadavg") in
    match String.split_on_char ' ' line with
    | one_min :: five_min :: fifteen_min :: _ ->
      Some {
        one_min_avg = float_of_string one_min;
        five_min_avg = float_of_string five_min;
        fifteen_min_avg = float_of_string fifteen_min;
      }
    | _ -> None
  with
  | Sys_error _ -> None
  | Failure _ -> None

let read_process_count () : process_count =
  let is_digit str = String.for_all Char.is_digit str in
  let proc_dirs = Sys.readdir "/proc" |> Array.to_list |> List.filter is_digit in
  let total_processes = List.length proc_dirs in
  let total_threads, n_running_tasks =
    List.fold_left (fun (thr_acc, run_acc) pid ->
      let task_dir = "/proc/" ^ pid ^ "/task" in
      let n_threads = Sys.readdir task_dir |> Array.length in
      let stat_file = "/proc/" ^ pid ^ "/stat" in
      let running = 
        try
          let stat = input_line (open_in stat_file) in
          String.get stat 0 = 'R'  (* Assuming state is the first char *)
        with _ -> false
      in
      (thr_acc + n_threads, run_acc + (if running then 1 else 0))
    ) (0, 0) proc_dirs
  in
  { total_processes; total_threads; n_running_tasks }

let read_process_stats pid =
  let filename = "/proc/" ^ string_of_int pid ^ "/stat" in
  let file = open_in filename in
  try
    let line = input_line file in
    let parts = String.split_on_char ' ' line in
    let utime = int_of_string (List.nth parts 13) in
    let stime = int_of_string (List.nth parts 14) in
    let total_cpu_time = utime + stime in
    let uid = int_of_string (List.nth parts 0) in (* Replace with correct index for UID *)
    let cmdline = List.nth parts 1 in (* Replace with correct index for command line *)
    let vm_rss = int_of_string (List.nth parts 23) in (* Replace with correct index for RSS *)
    close_in file;
    { pid; utime; stime; total_cpu_time; vm_rss; uid; cmdline }
  with End_of_file ->
    close_in file;
    { pid; utime = 0; stime = 0; total_cpu_time = 0; vm_rss = 0; uid = 0; cmdline = "" }

let list_pids () =
  Sys.readdir "/proc"
  |> Array.to_list
  |> List.filter_map (fun name ->
       try Some (int_of_string name) with
       | Failure _ -> None)

let collect_process_stats () =
  let pids = list_pids () in
  List.map read_process_stats pids       

let () =
  (* CPU Stats printing *)
  let cpu_stats_list = read_cpu_stats () in
  List.iter (fun cpu_stat ->
    Printf.printf "CPU: %s, User: %d, Nice: %d, System: %d, Idle: %d, IOwait: %d, IRQ: %d, SoftIRQ: %d\n"
      cpu_stat.cpu_id cpu_stat.user cpu_stat.nice cpu_stat.system cpu_stat.idle cpu_stat.iowait cpu_stat.irq cpu_stat.softirq
  ) cpu_stats_list;

  (* Memory Info printing *)
  match read_memory_info () with
  | Some mem_info ->
    Printf.printf "Total Memory: %d KB\nFree Memory: %d KB\nTotal Swap: %d KB\nFree Swap: %d KB\n"
      mem_info.mem_total mem_info.mem_free mem_info.swap_total mem_info.swap_free
  | None -> Printf.printf "Failed to read memory information.\n";

  match read_load_average () with
  | Some load_avg ->
    Printf.printf "Load Average - 1 min: %f, 5 min: %f, 15 min: %f\n"
      load_avg.one_min_avg load_avg.five_min_avg load_avg.fifteen_min_avg
  | None -> Printf.printf "Failed to read load average.\n";

  let proc_count = read_process_count () in
  Printf.printf "Total Processes: %d, Total Threads: %d, Running Tasks: %d\n"
    proc_count.total_processes proc_count.total_threads proc_count.n_running_tasks;
  
  let process_stats_list = collect_process_stats () in
  List.iter (fun ps -> 
    Printf.printf "PID: %d, UTime: %d, STime: %d, Total CPU: %d, VM RSS: %d, UID: %d, CMD: %s\n"
      ps.pid ps.utime ps.stime ps.total_cpu_time ps.vm_rss ps.uid ps.cmdline
  ) process_stats_list 