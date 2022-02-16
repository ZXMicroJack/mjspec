/* This file is part of fpga-spec by ZXMicroJack - see LICENSE.txt for moreinfo */
module keyboard(
  input [7:0] kbd_key,
  input kbd_key_valid,
  output [4:0] kvcxzsh,
  output [4:0] kgfdsa,
  output [4:0] ktrewq,
  output [4:0] k54321,
  output [4:0] k67890,
  output [4:0] kyuiop,
  output [4:0] khjklen,
  output [4:0] kbnmsssp,
  output [8:0] kspecial
  );

  ///////////////////   KEYBOARD   ///////////////////
  reg kq, kw, ke, kr, kt;

  reg ka, ks, kd, kf, kg;
  reg k1, k2, k3, k4, k5;
  reg ksh, kz, kx, kc, kv;

  reg k0, k9, k8, k7, k6;
  reg kp, ko, ki, ku, ky;
  reg ken, kl, kk, kj, kh;
  reg ksp, kss, km, kn, kb;

  reg kf12, kfpipe, kf11, kf10, kf9, kf8, kf7, kf6, kf5;
  reg released;

  // IN:    Reads keys (bit 0 to bit 4 inclusive)
  //
  //      0xfdfe  A, S, D, F, G                0xdffe  P, O, I, U, Y
  //      0xfefe  SHIFT, Z, X, C, V            0xeffe  0, 9, 8, 7, 6
  //      0xfbfe  Q, W, E, R, T                0xbffe  ENTER, L, K, J, H
  //      0xf7fe  1, 2, 3, 4, 5                0x7ffe  SPACE, SYM SHFT, M, N, B

  assign kvcxzsh = {!kv, !kc, !kx, !kz, !ksh};
  assign kgfdsa = {!kg, !kf, !kd, !ks, !ka};
  assign ktrewq = {!kt, !kr, !ke, !kw, !kq};
  assign k54321 = {!k5, !k4, !k3, !k2, !k1};
  assign k67890 = {!k6, !k7, !k8, !k9, !k0};
  assign kyuiop = {!ky, !ku, !ki, !ko, !kp};
  assign khjklen = {!kh, !kj, !kk, !kl, !ken};
  assign kbnmsssp = {!kb, !kn, !km, !kss, !ksp};
  assign kspecial = {kf5, kf6, kf7, kf8, kf9, kfpipe, kf10, kf11, kf12};

  always @ (posedge kbd_key_valid) begin
    if (kbd_key[7:0] == 8'hf0)
      released <= 1'b1;
    else begin
      case (kbd_key[7:0])
        8'h15: kq <= !released;
        8'h1d: kw <= !released;
        8'h24: ke <= !released;
        8'h2d: kr <= !released;
        8'h2c: kt <= !released;

        8'h1c: ka <= !released;
        8'h1b: ks <= !released;
        8'h23: kd <= !released;
        8'h2b: kf <= !released;
        8'h34: kg <= !released;

        8'h16: k1 <= !released;
        8'h1e: k2 <= !released;
        8'h26: k3 <= !released;
        8'h25: k4 <= !released;
        8'h2e: k5 <= !released;

        8'h12: ksh <= !released;
        8'h1a: kz <= !released;
        8'h22: kx <= !released;
        8'h21: kc <= !released;
        8'h2a: kv <= !released;

        8'h45: k0 <= !released;
        8'h46: k9 <= !released;
        8'h3e: k8 <= !released;
        8'h3d: k7 <= !released;
        8'h36: k6 <= !released;

        8'h4d: kp <= !released;
        8'h44: ko <= !released;
        8'h43: ki <= !released;
        8'h3c: ku <= !released;
        8'h35: ky <= !released;

        8'h5a: ken <= !released;
        8'h4b: kl <= !released;
        8'h42: kk <= !released;
        8'h3b: kj <= !released;
        8'h33: kh <= !released;

        8'h29: ksp <= !released;
        8'h14: kss <= !released;
        8'h3a: km <= !released;
        8'h31: kn <= !released;
        8'h32: kb <= !released;

        8'h07: kf12 <= !released;
        8'h0e: kfpipe <= !released;
        8'h78: kf11 <= !released;
        8'h09: kf10 <= !released;
        8'h01: kf9 <= !released;
        8'h0a: kf8 <= !released;
        8'h83: kf7 <= !released;
        8'h0b: kf6 <= !released;
        8'h03: kf5 <= !released;
      endcase
      released <= 1'b0;
    end
  end


endmodule
