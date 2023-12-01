open Core
open OUnit2
open Calculator

let assert_float_equal ~msg a b =
  assert_equal ~msg 1 ( Float.compare 0.01 (Float.abs (a -. b)) )

let test_calculate_cpu_usage _ =
  let cpu_stats_sample = {
    cpu_id = "cpu0";
    user = 4705;
    nice = 150;
    system = 1120;
    idle = 16250;
    iowait = 520;
    irq = 20;
    softirq = 5;
  } in
  let expected = 28.63 in
  let actual = calculate_cpu_usage cpu_stats_sample in
  assert_float_equal ~msg:"CPU usage calculation" expected actual

let test_calculate_memory_usage _ =
  let memory_info_sample = {
    mem_total = 8000000;
    mem_free = 2000000;
    swap_total = 4000000;
    swap_free = 3000000;
  } in
  let expected_memory, expected_swap = 5.72, 0.95 in
  let actual_memory, actual_swap = calculate_memory_usage memory_info_sample in
  assert_float_equal ~msg:"Memory usage calculation" expected_memory actual_memory;
  assert_float_equal ~msg:"Swap usage calculation" expected_swap actual_swap


let suite =
  "CalculatorTests" >::: [
    "test_calculate_cpu_usage" >:: test_calculate_cpu_usage;
    "test_calculate_memory_usage" >:: test_calculate_memory_usage;
  ]

let () =
  run_test_tt_main suite
