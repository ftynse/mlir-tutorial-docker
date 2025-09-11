module {
  // TODO: tile and fuse the matrix multiplication and the addition to 32x32x32
  // size, without affecting the ReLU.

  // TODO: outline the body of the tiled loop into a function, then replace it
  // with the call to the microkernel provided.

  func.func @fc_relu(%lhs: tensor<512x512xf32>, %rhs: tensor<512x512xf32>,
                     %bias: tensor<512x512xf32>, %output: tensor<512x512xf32>)
                     -> tensor<512x512xf32> {
    // Matrix-matrix multiplication.
    %matmul = linalg.matmul ins(%lhs, %rhs: tensor<512x512xf32>, tensor<512x512xf32>)
                            outs(%output: tensor<512x512xf32>) -> tensor<512x512xf32>

    // Elementwise addition.
    %biased = linalg.elementwise kind=#linalg.elementwise_kind<add>
      ins(%matmul, %bias : tensor<512x512xf32>, tensor<512x512xf32>)
      outs(%output : tensor<512x512xf32>) -> tensor<512x512xf32>

    // Elementwise max with 0 (ReLU).
    %c0f = arith.constant dense<0.0> : tensor<512x512xf32>
    %relued = linalg.elementwise kind=#linalg.elementwise_kind<max_signed>
      ins(%biased, %c0f : tensor<512x512xf32>, tensor<512x512xf32>)
      outs(%output : tensor<512x512xf32>) -> tensor<512x512xf32>
    func.return %relued : tensor<512x512xf32>
  }

  func.func private @microkernel(%lhs: tensor<32x32xf32>, %rhs: tensor<32x32xf32>, %accum: tensor<32x32xf32>) -> tensor<32x32xf32>

  module attributes {transform.with_named_sequence} {
    transform.named_sequence @__transform_main(%arg0: !transform.any_op) {
      transform.yield
    }
  }
}
