open Batteries

type process_count = {
    total_processes: int;
    total_threads: int;
    n_running_tasks: int;
}

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
  mem_total: int;  
  mem_free: int;   
  swap_total: int; 
  swap_free: int;  
}

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
}

type load_average_stats = {
  one_min_avg : float;
  five_min_avg : float;
  fifteen_min_avg : float;
}

module type CPUReader_type = sig
  val lines_of : string -> string list
end


module CPUReader : CPUReader_type = struct
  let lines_of filename = 
    List.of_enum (File.lines_of filename)   [@coverage off]
end


module type MemReader_type = sig
  val lines_of : string -> string Enum.t
end


module MemReader : MemReader_type = struct
  let lines_of filename = 
    File.lines_of filename    [@coverage off]
end


module type LoadAvgReader_type = sig
  val read_lvg : string -> string option
end


module LoadAvgReader : LoadAvgReader_type = struct
  let read_lvg filename =
    try let channel = open_in filename in     
      try let line = input_line channel in    
        close_in channel;                     
        Some line                             [@coverage off]
      with End_of_file ->                     
        close_in channel;
        None                                  [@coverage off]
    with Sys_error _ -> None                  [@coverage off]
end


module type ProcCountFileReader_type = sig
  val read_directory : string -> string array option
  val read_line : string -> string option
end


module ProcCountReader : ProcCountFileReader_type = struct
  let read_directory path =
    try Some (Sys.readdir path)     [@coverage off]
    with Sys_error _ -> None        [@coverage off]

  let read_line filename =
    try let channel = open_in filename in         
      try let line = input_line channel in        
        close_in channel;
        Some line                                 [@coverage off]
      with End_of_file ->                         
        close_in channel;
        None                                      [@coverage off]
    with Sys_error _ -> None                      [@coverage off]
end

module type ProcessesFileReader_type = sig
  val read_line : string -> string option
  val read_directory : string -> string array option
  val getpwuid : int -> (string, string) result
end


module ProcessesReader : ProcessesFileReader_type = struct
  let read_line filename =
    try
      let channel = open_in filename in
      try
        let line = input_line channel in
        close_in channel;
        Some line
      with End_of_file ->     
        close_in channel;
        None               
    with Sys_error _ -> None     

  let read_directory path =
    try Some (Sys.readdir path)
    with Sys_error _ -> None

  let getpwuid uid =
    try Ok (Unix.getpwuid uid).Unix.pw_name
    with Not_found -> Error "Unknown"
end


module Process_count_collector(FileReader : ProcCountFileReader_type) = struct
  let read_process_count () : process_count =
    let is_digit str = String.for_all Char.is_digit str in

  let proc_dirs = match FileReader.read_directory "/proc" with
                  | Some dirs -> Array.to_list dirs |> List.filter is_digit
                  | None -> []      [@coverage off]
  in let total_processes = List.length proc_dirs in
  let total_threads, n_running_tasks =
    List.fold_left (fun (thr_acc, run_acc) pid ->
      let task_dir = "/proc/" ^ pid ^ "/task" in
      let n_threads = match FileReader.read_directory task_dir with
                      | Some tasks -> Array.length tasks
                      | None -> 0       [@coverage off]
      in
      let stat_file = "/proc/" ^ pid ^ "/stat" in
      let running = 
        match FileReader.read_line stat_file with
        | Some stat -> String.get stat 0 = 'R'  
        | None -> false     [@coverage off]
      in
      (thr_acc + n_threads, run_acc + (if running then 1 else 0))
    ) (0, 0) proc_dirs
  in
  { total_processes; total_threads; n_running_tasks }
end

module LoadAvg_collector(FileReader : LoadAvgReader_type) = struct
  let read_load_average () : load_average_stats option =
    match FileReader.read_lvg "/proc/loadavg" with
    | Some line ->
      begin
        match String.split_on_char ' ' line with
        | one_min :: five_min :: fifteen_min :: _ ->
          Some {
            one_min_avg = float_of_string one_min;
            five_min_avg = float_of_string five_min;
            fifteen_min_avg = float_of_string fifteen_min;
          }
        | _ -> None   [@coverage off]
      end
    | None -> None    [@coverage off]
end

module Mem_collector(FileReader : MemReader_type) = struct 
  let read_memory_info () : memory_info option =
    let meminfo = FileReader.lines_of "/proc/meminfo" in
    let parse_line line =
      match String.split_on_char ':' line with
      | [key; value] ->
        let value = String.trim value |> String.split_on_char ' ' |> List.hd in
        begin
          try Some (String.trim key, int_of_string value)
          with Failure _ -> None      [@coverage off]
        end
      | _ -> None     [@coverage off]
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
    with Not_found -> None    [@coverage off]
end

module Cpu_collector (FileReader : CPUReader_type) = struct
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
    | _ -> None     [@coverage off]

  let read_cpu_stats () : cpu_stats list =
    let lines = FileReader.lines_of "/proc/stat" in
    List.fold_left (fun acc line ->
      if String.starts_with line "cpu" && not (String.equal line "cpu") then
        match parse_cpu_stats_line line with
        | Some stats -> stats :: acc
        | None -> acc     [@coverage off]
      else acc          [@coverage off]
    ) [] lines
  let string_of_cpu_stats stat =
    Printf.sprintf "\ncpu_id: %s, user: %d, nice: %d, system: %d, idle: %d, iowait: %d, irq: %d, softirq: %d\n" 
      stat.cpu_id stat.user stat.nice stat.system stat.idle stat.iowait stat.irq stat.softirq   [@coverage off]
end

module Processes_collector(FileReader : ProcessesFileReader_type) = struct
let read_process_stats (pid: int) : process_stats =
  let stat_filename = "/proc/" ^ string_of_int pid ^ "/stat" in
  let stat_option = FileReader.read_line stat_filename in
  match stat_option with
  | Some stat_line ->
    let stat_parts = String.split_on_char ' ' stat_line in
    let utime = int_of_string (List.nth stat_parts 13) in
    let stime = int_of_string (List.nth stat_parts 14) in
    let total_time = utime + stime in
    let total_cpu_time = 0 in
    let vm_rss = int_of_string (List.nth stat_parts 23) in
    let uid = int_of_string (List.nth stat_parts 0) in
    let cmdline = List.nth stat_parts 1 in
    let state = List.nth stat_parts 2 in
    let username = 
      match FileReader.getpwuid uid with
      | Ok name -> name
      | Error _ -> "Unknown"
    in
    { pid; utime; stime; total_time; total_cpu_time; vm_rss; state; username; uid; cmdline }
  | None -> { pid; utime = 0; stime = 0; total_cpu_time = 0; total_time = 0; vm_rss = 0; state = ""; username = ""; uid = 0; cmdline = "" }   [@coverage off]

let collect_process_stats : process_stats list =
  match FileReader.read_directory "/proc" with
  | Some dirs ->
    dirs
    |> Array.to_list
    |> List.filter_map (fun name ->
         try Some (int_of_string name) with
         | Failure _ -> None)
    |> List.map read_process_stats
  | None -> []      [@coverage off]
end

module RealLoadAvgCollector = LoadAvg_collector(LoadAvgReader)
module RealProcCountCollector = Process_count_collector(ProcCountReader)
module RealMemCollector = Mem_collector(MemReader)
module RealProcessesCollector = Processes_collector(ProcessesReader)
module RealCPUCollector = Cpu_collector(CPUReader)
