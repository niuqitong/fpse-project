[@@@warning "-34"]

open Core
open Batteries
open OUnit2
open Calculator
open Collector
module P = Collector
module C = Calculator

type cpu_stats = P.cpu_stats
type memory_info = P.memory_info
type load_average_stats = P.load_average_stats
type process_count = P.process_count

let assert_float_equal ~msg a b =
  assert_equal ~msg 1 ( Float.compare 0.01 (Float.abs (a -. b)) )
let test_compare_pid _ =
  let proc_a = {pid = 1; user = ""; state = ""; cpu_percentage = 0.0; mem_percentage = 0.0; command = ""} in
  let proc_b = {pid = 2; user = ""; state = ""; cpu_percentage = 0.0; mem_percentage = 0.0; command = ""} in
  assert_equal 0 (Query.compare_pid proc_a proc_a); 
  assert_bool "proc_a < proc_b" (Query.compare_pid proc_a proc_b < 0); 
  assert_bool "proc_b > proc_a" (Query.compare_pid proc_b proc_a > 0)

let test_compare_user _ =
  let proc_a = {pid = 1; user = "root"; state = ""; cpu_percentage = 0.0; mem_percentage = 0.0; command = ""} in
  let proc_b = {pid = 2; user = "aroot"; state = ""; cpu_percentage = 0.0; mem_percentage = 0.0; command = ""} in
  assert_equal 0 (Query.compare_user proc_a proc_a); 
  assert_bool "proc_a < proc_b" (Query.compare_user proc_a proc_b > 0); 
  assert_bool "proc_b > proc_a" (Query.compare_user proc_b proc_a < 0)
  let test_compare_state _ =
    let proc_a = {pid = 1; user = "root"; state = "S"; cpu_percentage = 0.0; mem_percentage = 0.0; command = ""} in
    let proc_b = {pid = 2; user = "aroot"; state = "R"; cpu_percentage = 0.0; mem_percentage = 0.0; command = ""} in
    assert_equal 0 (Query.compare_state proc_a proc_a); 
    assert_bool "proc_a < proc_b" (Query.compare_state proc_a proc_b > 0); 
    assert_bool "proc_b > proc_a" (Query.compare_state proc_b proc_a < 0)
let test_compare_cpu _ =
  let proc_a = {pid = 1; user = "root"; state = "S"; cpu_percentage = 0.1; mem_percentage = 0.0; command = ""} in
  let proc_b = {pid = 2; user = "aroot"; state = "R"; cpu_percentage = 0.2; mem_percentage = 0.0; command = ""} in
  assert_equal 0 (Query.compare_cpu proc_a proc_a); 
  assert_bool "proc_a < proc_b" (Query.compare_cpu proc_a proc_b < 0); 
  assert_bool "proc_b > proc_a" (Query.compare_cpu proc_b proc_a > 0)

  let test_compare_mem _ =
    let proc_a = {pid = 1; user = "root"; state = "S"; cpu_percentage = 0.1; mem_percentage = 0.1; command = ""} in
    let proc_b = {pid = 2; user = "aroot"; state = "R"; cpu_percentage = 0.2; mem_percentage = 0.2; command = ""} in
    assert_equal 0 (Query.compare_mem proc_a proc_a); 
    assert_bool "proc_a < proc_b" (Query.compare_mem proc_a proc_b < 0); 
    assert_bool "proc_b > proc_a" (Query.compare_mem proc_b proc_a > 0)

let test_order_by _ =
  let lst = [
    {pid = 2; user = "user2"; state = "sleeping"; cpu_percentage = 30.0; mem_percentage = 40.0; command = "command2"};
    {pid = 1; user = "user1"; state = "running"; cpu_percentage = 20.0; mem_percentage = 50.0; command = "command1"}
  ] in
  let expected_pid_asc = [
    {pid = 1; user = "user1"; state = "running"; cpu_percentage = 20.0; mem_percentage = 50.0; command = "command1"};
    {pid = 2; user = "user2"; state = "sleeping"; cpu_percentage = 30.0; mem_percentage = 40.0; command = "command2"}
  ] in
  let expected_pid_desc = List.rev expected_pid_asc in
  assert_equal expected_pid_asc (Query.order_by ~pid:true ~asc:true lst);
  assert_equal expected_pid_desc (Query.order_by ~pid:true lst);

  let expected_cpu_asc = [
      {pid = 1; user = "user1"; state = "running"; cpu_percentage = 20.0; mem_percentage = 50.0; command = "command1"};
      {pid = 2; user = "user2"; state = "sleeping"; cpu_percentage = 30.0; mem_percentage = 40.0; command = "command2"}
    ] in
    let expected_cpu_desc = List.rev expected_cpu_asc in
    assert_equal expected_cpu_asc (Query.order_by ~cpu:true ~asc:true lst);
    assert_equal expected_cpu_desc (Query.order_by ~cpu:true lst);
    
    let expected_mem_asc = [
      {pid = 2; user = "user2"; state = "sleeping"; cpu_percentage = 30.0; mem_percentage = 40.0; command = "command2"};
      {pid = 1; user = "user1"; state = "running"; cpu_percentage = 20.0; mem_percentage = 50.0; command = "command1"}
    ] in
    let expected_mem_desc = List.rev expected_mem_asc in
    assert_equal expected_mem_asc (Query.order_by ~mem:true ~asc:true lst);
    assert_equal expected_mem_desc (Query.order_by ~mem:true lst);

    let expected_user_asc = [
      {pid = 1; user = "user1"; state = "running"; cpu_percentage = 20.0; mem_percentage = 50.0; command = "command1"};
      {pid = 2; user = "user2"; state = "sleeping"; cpu_percentage = 30.0; mem_percentage = 40.0; command = "command2"}
    ] in
    let expected_user_desc = List.rev expected_user_asc in
    assert_equal expected_user_asc (Query.order_by ~user:true ~asc:true lst);
    assert_equal expected_user_desc (Query.order_by ~user:true lst);

    let expected_state_asc = [
      {pid = 1; user = "user1"; state = "running"; cpu_percentage = 20.0; mem_percentage = 50.0; command = "command1"};
      {pid = 2; user = "user2"; state = "sleeping"; cpu_percentage = 30.0; mem_percentage = 40.0; command = "command2"}
    ] in
    let expected_state_desc = List.rev expected_state_asc in
    assert_equal expected_state_asc (Query.order_by ~state:true ~asc:true lst);
    assert_equal expected_state_desc (Query.order_by ~state:true lst);
    assert_raises (Failure "No sorting criterion provided") (fun () -> Query.order_by lst)

let test_filter_cpu_range _ =
    let lst = [
      {pid = 1; user = "user1"; state = "running"; cpu_percentage = 0.6; mem_percentage = 40.0; command = "command1"};
      {pid = 2; user = "user2"; state = "sleeping"; cpu_percentage = 0.4; mem_percentage = 60.0; command = "command2"}
    ] in
    let expected = [
      {pid = 1; user = "user1"; state = "running"; cpu_percentage = 0.6; mem_percentage = 40.0; command = "command1"}
    ] in
    let result = Query.filter ~cpu_range:(0.5, 1.0) lst in
    assert_equal expected result 

let test_filter_mem_range _ =
  let lst = [
    {pid = 1; user = "user1"; state = "running"; cpu_percentage = 0.6; mem_percentage = 40.0; command = "command1"};
    {pid = 2; user = "user2"; state = "sleeping"; cpu_percentage = 0.4; mem_percentage = 60.0; command = "command2"}
  ] in
  let expected = [
    {pid = 1; user = "user1"; state = "running"; cpu_percentage = 0.6; mem_percentage = 40.0; command = "command1"}
  ] in
  let result = Query.filter ~mem_range:(10.0, 50.0) lst in
  assert_equal expected result     
let test_filter_state _ =
  let lst = [
    {pid = 1; user = "user1"; state = "running"; cpu_percentage = 0.6; mem_percentage = 40.0; command = "command1"};
    {pid = 2; user = "user2"; state = "sleeping"; cpu_percentage = 0.4; mem_percentage = 60.0; command = "command2"}
  ] in
  let expected = [
    {pid = 1; user = "user1"; state = "running"; cpu_percentage = 0.6; mem_percentage = 40.0; command = "command1"}
  ] in
  let result = Query.filter ~state: "running" lst in
  assert_equal expected result 
let test_filter_user _ =
  let lst = [
    {pid = 1; user = "user1"; state = "running"; cpu_percentage = 0.6; mem_percentage = 40.0; command = "command1"};
    {pid = 2; user = "user2"; state = "sleeping"; cpu_percentage = 0.4; mem_percentage = 60.0; command = "command2"}
  ] in
  let expected = [
    {pid = 1; user = "user1"; state = "running"; cpu_percentage = 0.6; mem_percentage = 40.0; command = "command1"}
  ] in
  let result = Query.filter ~user: "user1" lst in
  assert_equal expected result 

module MockCPUFileReader : CPUReader_type = struct
  let lines_of _ = 
    ["cpu0 123 456 789 0 0 0 0 0"; "cpu1 121 456 7890 0 0 0 0 0";]
end  
module CPUCollectorTest = Cpu_collector(MockCPUFileReader)

let test_read_cpu_stats _ =
  let stats = CPUCollectorTest.read_cpu_stats () in
  assert_equal 2 (List.length stats) ~msg:"The length of the stats list should be 2";

  match stats with
  | [stat1; stat2] ->
    assert_equal "cpu1" stat1.cpu_id ~msg:"The cpu_id of the first stat should be 'cpu1'";
    assert_equal 121 stat1.user ~msg:"The user value of the first stat should be 121";

    assert_equal "cpu0" stat2.cpu_id ~msg:"The cpu_id of the second stat should be 'cpu0'";
    assert_equal 123 stat2.user ~msg:"The user value of the second stat should be 123";

  | _ -> assert_failure "List of stats should contain exactly two elements"
  
module MockFileReader : LoadAvgReader_type = struct
  let read_lvg _ = Some "1.00 0.75 0.50"
end
module LvgCollectorTest = LoadAvg_collector(MockFileReader)

let test_load_average _ = 
  let lvg = LvgCollectorTest.read_load_average () in
  match lvg with
  | Some v ->
    assert_float_equal ~msg:"5 min load avg" 0.75 v.five_min_avg
  | None -> assert_failure "List of stats should contain exactly two elements"

module MockProcCountFileReader : ProcCountFileReader_type = struct
  let read_directory path =
    match path with
    | "/proc" -> Some [| "123"; "456"; "789"; "non-numeric" |]
    | "/proc/123/task" -> Some [| "1"; "2" |]
    | "/proc/456/task" -> Some [| "1" |]
    | "/proc/789/task" -> Some [| |]
    | _ -> None

  let read_line path =
    match path with
    | "/proc/123/stat" -> Some "R ..."
    | "/proc/456/stat" -> Some "S ..."
    | "/proc/789/stat" -> Some "R ..."
    | _ -> None
end
module ProcessCountCollectorTest = Process_count_collector(MockProcCountFileReader)
let test_read_process_count _ =
  let process_count = ProcessCountCollectorTest.read_process_count () in
  assert_equal 3 process_count.total_processes ~msg:"Should have 3 total processes";
  assert_equal 3 process_count.total_threads ~msg:"Should have 3 total threads";
  assert_equal 2 process_count.n_running_tasks ~msg:"Should have 2 running tasks"

module MockMemReader : MemReader_type = struct
  let lines_of _ =
    List.enum [
      "MemTotal: 8000 kB";
      "MemFree: 2000 kB";
      "SwapTotal: 2000 kB";
      "SwapFree: 1000 kB";
    ]
end
  
module MemCollectorTest = Mem_collector(MockMemReader)

let test_read_memory_info _ =
  match MemCollectorTest.read_memory_info () with
  | Some mem_info ->
    assert_equal 8000 mem_info.mem_total ~msg:"MemTotal should be 8000";
    assert_equal 2000 mem_info.mem_free ~msg:"MemFree should be 2000";
    assert_equal 2000 mem_info.swap_total ~msg:"SwapTotal should be 2000";
    assert_equal 1000 mem_info.swap_free ~msg:"SwapFree should be 1000";
  | None -> assert_failure "Expected Some memory_info, got None"

module MockProcessesFileReader : ProcessesFileReader_type = struct
  let read_directory path =
    match path with
    | "/proc" -> Some [| "123"; "456" |] 
    | _ -> None

  let read_line path =
    match path with
    | "/proc/123/stat" -> Some "17 (cpuhp/0) S 2 0 0 0 -1 69238848 0 0 0 0 0 0 0 0 20 0 1 0 0 0 0 18446744073709551615 0 0 0 0 0 0 0 2147483647 0 0 0 0 17 0 0 0 0 0 0 0 0 0 0 0 0 0 0"  
    | "/proc/456/stat" -> Some "3 (rcu_gp) I 2 0 0 0 -1 69238880 0 0 0 0 0 0 0 0 0 -20 1 0 0 0 0 18446744073709551615 0 0 0 0 0 0 0 2147483647 0 0 0 0 17 0 0 0 0 0 0 0 0 0 0 0 0 0 0"
    | _ -> None

  let getpwuid uid =
    match uid with
    | 1000 -> Ok "user1"
    | _ -> Error "Unknown"
end

module ProcessesCollectorTest = Processes_collector(MockProcessesFileReader)

let test_collect_process_stats _ =
  let process_stats_list = ProcessesCollectorTest.collect_process_stats () in
  assert_equal 2 (List.length process_stats_list) ~msg:"Should have 2 processes";
  match process_stats_list with
  |[p1; p2] -> 
    assert_equal "S" p1.state;
    assert_equal "I" p2.state;
  | _ -> assert_failure "List of stats should contain exactly two elements"

let test_calculate_cpu_usage _ =
  let open Computer in
  let cpu_stats_samples = [
    {
      P.cpu_id = "cpu0";
      user = 4705;
      nice = 150;
      system = 1120;
      idle = 16250;
      iowait = 520;
      irq = 20;
      softirq = 5;
    };
    {
      P.cpu_id = "cpu1";
      user = 4705;
      nice = 150;
      system = 1120;
      idle = 16250;
      iowait = 520;
      irq = 20;
      softirq = 5;
    }
  ] in

  let actual = calculate_cpu_usage cpu_stats_samples in

  match actual with
  | [c1; c2] -> 
    assert_float_equal ~msg:"assert cpu usage" c1.cpu_usage_pct 28.63;
    assert_float_equal ~msg:"assert cpu usage" c2.cpu_usage_pct 28.63;
  | _ -> assert_failure "cpu usage fail"  

  
let test_calculate_memory_usage _ =
  let open Computer in
  let memory_info_sample = {
    P.mem_total = 8000000;
    mem_free = 2000000;
    swap_total = 1024 * 1024;
    swap_free = 256 * 1024;
  } in
  let expected_memory, expected_swap = 5.72, 768.0 in
  let used_memory, _ = calculate_memory_usage memory_info_sample in
  let used_swap, _ = calculate_swap_usage memory_info_sample in
  assert_float_equal ~msg:"Memory usage calculation" used_memory  expected_memory;
  assert_float_equal ~msg:"Swap usage calculation" used_swap expected_swap

let test_calculate_swap_usage _ =
  let info = {mem_total = 0; mem_free = 0; swap_total = 1024 * 1024; swap_free = 512 * 1024} in
  let expected = (512.0, 1024.0) in  
  let result = Computer.calculate_swap_usage info in

  let (expected_used, expected_total) = expected in
  let (result_used, result_total) = result in

  assert_float_equal ~msg:"Used swap percentage should be close to expected value" expected_used result_used;
  assert_float_equal ~msg:"Total swap percentage should be close to expected value" expected_total result_total
  
let test_calculate_process_list _ =
  let open Computer in
  let proc_ls = [
    {pid = 1; utime = 10000; stime = 50; starttime = 0; sys_uptime = 100.0;  vm_rss = 500; state = "Running"; username = "user1"; uid = 1001; cmdline = "command1"};
    (* (10000 + 500) / (100 * 1000) - 0 *)
    {pid = 2; utime = 20000; stime = 50; starttime = 0; sys_uptime = 100.0; vm_rss = 1000; state = "Sleeping"; username = "user2"; uid = 1002; cmdline = "command2"}
  ] in
  let total_mem_kb = 8000 in
  let result = calculate_process_list total_mem_kb proc_ls in
  match result with
  |[p1; p2] -> 
    assert_float_equal ~msg:"assert proc ls" p1.cpu_percentage 10.5;
    assert_float_equal ~msg:"assert proc ls" p2.cpu_percentage 20.5;
  | _ -> assert_failure "proc ls fail"  

  let test_calculate_all_fields _ =
    let cpu_stats_ls = [
      {cpu_id = "cpu0"; user = 100; nice = 10; system = 50; idle = 840; iowait = 0; irq = 0; softirq = 0};
    ] in
    let mem_info = {mem_total = 8000; mem_free = 6000; swap_total = 2000; swap_free = 1000} in
    let load_avg_stats = {one_min_avg = 0.5; five_min_avg = 0.75; fifteen_min_avg = 1.0} in
    let proc_count = {total_processes = 100; total_threads = 200; n_running_tasks = 50} in
    let proc_list = [
      {pid = 1; utime = 100; stime = 50; starttime = 0; sys_uptime = 100.0; vm_rss = 500; state = "Running"; username = "user1"; uid = 1001; cmdline = "command1"};
    ] in
  
    let result = Computer.calculate cpu_stats_ls mem_info load_avg_stats proc_count proc_list in
    assert_float_equal ~msg:"test all fields" result.load_avg.five_min_avg 0.75 
let query_tests =
  "QueryTests" >::: [
    "test_compare_pid" >:: test_compare_pid;
    "test_compare_user" >:: test_compare_user;
    "test_compare_state" >:: test_compare_state;
    "test_compare_cpu" >:: test_compare_cpu;
    "test_compare_mem" >:: test_compare_mem;

    "test_order_by" >:: test_order_by;
    "test_filter_cpu_range" >:: test_filter_cpu_range;
    "test_filter_mem_range" >:: test_filter_mem_range;
    "test_filter_state" >:: test_filter_state;
    "test_filter_user" >:: test_filter_user;
    
  ]  
    
let calculator_tests =
  "CalculatorTests" >::: [
    "test_calculate_cpu_usage" >:: test_calculate_cpu_usage;
    "test_calculate_memory_usage" >:: test_calculate_memory_usage;
    "test_calculate_swap_usage" >:: test_calculate_swap_usage;
    "test_calculate_process_list" >:: test_calculate_process_list;
  ]
let collector_tests = 
  "collectorTests" >::: [
  "test_read_cpu_stats" >:: test_read_cpu_stats;
  "test_load_average." >:: test_load_average;
  "test_read_process_count." >:: test_read_process_count;
  "test_read_memory_info." >:: test_read_memory_info;
  "test_collect_process_stats." >:: test_collect_process_stats;
  "test_calculate_all_fields." >:: test_calculate_all_fields;
  

]  
  

  let () =
  run_test_tt_main ("All tests" >::: [ query_tests; calculator_tests; collector_tests])
