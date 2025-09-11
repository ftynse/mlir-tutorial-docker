module {
  // TODO: emit remarks at "addf" operations. 

  func.func @foo(%arg0: f32, %arg1: f32, %arg2: f32) -> f32 {
    %0 = arith.addf %arg0, %arg1 : f32
    %1 = arith.mulf %0, %arg2 : f32
    %2 = arith.addf %1, %arg0 : f32
    return %2 : f32
  }

  module attributes {transform.with_named_sequence} {
    transform.named_sequence @__transform_main(%arg0: !transform.any_op) {
      transform.yield
    }
  }

}
