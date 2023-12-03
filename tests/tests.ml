[@@@warning "-34"]

open Core
open OUnit2
open Calculator
module P = Collector
module C = Calculator

type cpu_stats = P.cpu_stats
type memory_info = P.memory_info
type load_average_stats = P.load_average_stats
type process_count = P.process_count

let assert_float_equal ~msg a b =
  assert_equal ~msg 1 ( Float.compare 0.01 (Float.abs (a -. b)) )

let test_calculate_cpu_usage _ =
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
  (* List.iter2 ~f:(fun expected_cpu actual_cpu ->
    assert_float_equal ~msg:("CPU usage calculation for " ^ expected_cpu.cpu_id)
                        expected_cpu.cpu_usage_pct actual_cpu.cpu_usage_pct
  ) expected actual; *)
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
  (* let _, used_swap = calculate_swap_usage memory_info_sample in *)
  assert_float_equal ~msg:"Memory usage calculation" used_memory  expected_memory
  (* assert_float_equal ~msg:"Swap usage calculation" used_swap expected_swap *)


let suite =
  "CalculatorTests" >::: [
    "test_calculate_cpu_usage" >:: test_calculate_cpu_usage;
    "test_calculate_memory_usage" >:: test_calculate_memory_usage;
  ]

let () =
  run_test_tt_main suite
