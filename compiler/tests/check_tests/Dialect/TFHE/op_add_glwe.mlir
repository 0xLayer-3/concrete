// RUN: concretecompiler --action=roundtrip %s 2>&1| FileCheck %s

// CHECK-LABEL: func.func @add_glwe(%arg0: !TFHE.glwe<{1024,12,64}{7}>, %arg1: !TFHE.glwe<{1024,12,64}{7}>) -> !TFHE.glwe<{1024,12,64}{7}>
func.func @add_glwe(%arg0: !TFHE.glwe<{1024,12,64}{7}>, %arg1: !TFHE.glwe<{1024,12,64}{7}>) -> !TFHE.glwe<{1024,12,64}{7}> {
  // CHECK-NEXT: %[[V1:.*]] = "TFHE.add_glwe"(%arg0, %arg1) : (!TFHE.glwe<{1024,12,64}{7}>, !TFHE.glwe<{1024,12,64}{7}>) -> !TFHE.glwe<{1024,12,64}{7}>
  // CHECK-NEXT: return %[[V1]] : !TFHE.glwe<{1024,12,64}{7}>

  %0 = "TFHE.add_glwe"(%arg0, %arg1): (!TFHE.glwe<{1024,12,64}{7}>, !TFHE.glwe<{1024,12,64}{7}>) -> (!TFHE.glwe<{1024,12,64}{7}>)
  return %0: !TFHE.glwe<{1024,12,64}{7}>
}
