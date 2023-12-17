[@@@warning "-34"]

open Core
open Batteries
open OUnit2
(* open Calculator *)
open Collector
module P = Collector
(* module C = Calculator *)

(* type cpu_stats = P.cpu_stats
type memory_info = P.memory_info
type load_average_stats = P.load_average_stats
type process_count = P.process_count *)

let assert_float_equal ~msg a b =
  assert_equal ~msg 1 ( Float.compare 0.01 (Float.abs (a -. b)) )

module MockCPUFileReader : CPUReader = struct
  let lines_of _ = 
    ["cpu0 123 456 789 0 0 0 0 0"; "cpu1 121 456 7890 0 0 0 0 0";]
end  
module CPUCollectorTest = Cpu_collector(MockCPUFileReader)

let test_read_cpu_stats _ =
  let stats = CPUCollectorTest.read_cpu_stats () in
  (* List.iter ~f:(fun stat -> 
    Printf.printf "Stat: %s\n" (CPUCollectorTest.string_of_cpu_stats stat)
  ) stats; *)
  assert_equal 2 (List.length stats) ~msg:"The length of the stats list should be 2";

  match stats with
  | [stat1; stat2] ->
    assert_equal "cpu1" stat1.cpu_id ~msg:"The cpu_id of the first stat should be 'cpu1'";
    assert_equal 121 stat1.user ~msg:"The user value of the first stat should be 121";

    assert_equal "cpu0" stat2.cpu_id ~msg:"The cpu_id of the second stat should be 'cpu0'";
    assert_equal 123 stat2.user ~msg:"The user value of the second stat should be 123";

  | _ -> assert_failure "List of stats should contain exactly two elements"
  
module MockFileReader : LoadAvgReader = struct
  let read_lvg _ = Some "1.00 0.75 0.50"
end
module LvgCollectorTest = LoadAvg_collector(MockFileReader)

let test_load_average _ = 
  let lvg = LvgCollectorTest.read_load_average () in
  match lvg with
  | Some v ->
    assert_float_equal ~msg:"5 min load avg" 0.75 v.five_min_avg
  | None -> assert_failure "List of stats should contain exactly two elements"

module MockProcCountFileReader : ProcCountFileReader = struct
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
  let process_count = ProcessCountCollectorTest.read_process_count in
  assert_equal 3 process_count.total_processes ~msg:"Should have 3 total processes";
  assert_equal 3 process_count.total_threads ~msg:"Should have 3 total threads";
  assert_equal 2 process_count.n_running_tasks ~msg:"Should have 2 running tasks"

module MockMemReader : MemReader = struct
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

module MockProcessesFileReader : ProcessesFileReader = struct
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

module ProcessesCollectorTest = ProcessesCollector(MockProcessesFileReader)

let test_collect_process_stats _ =
  let process_stats_list = ProcessesCollectorTest.collect_process_stats in
  assert_equal 2 (List.length process_stats_list) ~msg:"Should have 2 processes";
  match process_stats_list with
  |[p1; p2] -> 
    assert_equal "S" p1.state;
    assert_equal "I" p2.state;
  | _ -> assert_failure "List of stats should contain exactly two elements"

(* let test_calculate_cpu_usage _ =
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
  let expected = [
    { cpu_id = "cpu0"; cpu_usage_pct = 28.63 }; 
    { cpu_id = "cpu1"; cpu_usage_pct = 28.63 }  
  ] in
  let actual = calculate_cpu_usage cpu_stats_samples in

  assert_equal (List.length expected) (List.length actual) ~msg:"List length mismatch";
  
  let compare_cpu_usage expected_cpu actual_cpu =
    Float.compare 0.01 (Float.abs (expected_cpu.cpu_usage_pct -. actual_cpu.cpu_usage_pct)) = 1
  in
  assert (List.for_all2_exn ~f:compare_cpu_usage expected actual) 
  
let test_calculate_memory_usage _ =
  let memory_info_sample = {
    P.mem_total = 8000000;
    mem_free = 2000000;
    swap_total = 4000000;
    swap_free = 3000000;
  } in
  let expected_memory, expected_swap = 5.72, 0.95 in
  let used_memory, _ = calculate_memory_usage memory_info_sample in
  let used_swap, _ = calculate_swap_usage memory_info_sample in
  assert_float_equal ~msg:"Memory usage calculation" used_memory  expected_memory;
  assert_float_equal ~msg:"Swap usage calculation" used_swap expected_swap


let suite =
  "CalculatorTests" >::: [
    "test_calculate_cpu_usage" >:: test_calculate_cpu_usage;
    "test_calculate_memory_usage" >:: test_calculate_memory_usage;
  ] *)
let collector_tests = 
  "collectorTests" >::: [
  "test_read_cpu_stats" >:: test_read_cpu_stats;
  "test_load_average." >:: test_load_average;
  "test_read_process_count." >:: test_read_process_count;
  "test_read_memory_info." >:: test_read_memory_info;
  "test_collect_process_stats." >:: test_collect_process_stats;

]  
  

(* let () =
  run_test_tt_main ("All tests" >::: [suite; collector_tests]) *)
  let () =
  run_test_tt_main ("All tests" >::: [ collector_tests])
