/* This file is part of fpga-spec by ZXMicroJack - see LICENSE.txt for moreinfo */
module zxkeyboard(
  input [7:0] kbd_key,
  input kbd_key_valid,
  output [4:0] kvcxzsh_zx,
  output [4:0] kgfdsa,
  output [4:0] ktrewq,
  output [4:0] k54321,
  output [4:0] k67890,
  output [4:0] kyuiop,
  output [4:0] khjklen,
  output [4:0] kbnmsssp_zx,
  output [8:0] kspecial,
  output [4:0] kcxzsssh_ja,
  output [4:0] kvbnmsp_ja
  );

  ///////////////////   KEYBOARD   ///////////////////
  reg kq, kw, ke, kr, kt;

  reg ka, ks, kd, kf, kg;
  reg k1, k2, k3, k4, k5;
  reg kz, kx, kc, kv;
  wire ksh;

  reg k0, k9, k8, k7, k6;
  reg kp, ko, ki, ku, ky;
  reg ken, kl, kk, kj, kh;
  reg ksp, kss, km, kn, kb;

  reg kf12, kfpipe, kf11, kf10, kf9, kf8, kf7, kf6, kf5;
  reg released = 1'b0;
  reg extended = 1'b0;
  reg special = 1'b0;
  reg shifted = 1'b0;

  // IN:    Reads keys (bit 0 to bit 4 inclusive)
  //
  //      0xfdfe  A, S, D, F, G                0xdffe  P, O, I, U, Y
  //      0xfefe  SHIFT, Z, X, C, V            0xeffe  0, 9, 8, 7, 6
  //      0xfbfe  Q, W, E, R, T                0xbffe  ENTER, L, K, J, H
  //      0xf7fe  1, 2, 3, 4, 5                0x7ffe  SPACE, SYM SHFT, M, N, B

  assign kvcxzsh_zx = {!kv, !kc, !kx, !kz, !ksh};
  assign kgfdsa = {!kg, !kf, !kd, !ks, !ka};
  assign ktrewq = {!kt, !kr, !ke, !kw, !kq};
  assign k54321 = {!k5, !k4, !k3, !k2, !k1};
  assign k67890 = {!k6, !k7, !k8, !k9, !k0};
  assign kyuiop = {!ky, !ku, !ki, !ko, !kp};
  assign khjklen = {!kh, !kj, !kk, !kl, !ken};
  assign kbnmsssp_zx = {!kb, !kn, !km, !kss, !ksp};
  assign kspecial = {kf5, kf6, kf7, kf8, kf9, kfpipe, kf10, kf11, kf12};
  assign kcxzsssh_ja = {!kc, !kx, !kz, !kss, !ksh};
  assign kvbnmsp_ja = {!kv, !kb, !kn, !km, !ksp};
  assign ksh = shifted && !special;

  always @ (posedge kbd_key_valid) begin
    if (kbd_key[7:0] == 8'hf0)
      released <= 1'b1;
		else if (kbd_key[7:0] == 8'he0)
			extended <= 1'b1;
    else begin
      case (kbd_key[7:0])
				8'h66: {k0, shifted} <= {!released, !released}; // bs
				8'h58: {k2, shifted} <= {!released, !released}; // caps

				8'h70: k0 <= !released; // 0
				8'h69: k1 <= !released; // 1
				8'h72: if (extended) {k6, shifted} <= {!released, !released}; else k2 <= !released; // 2
				8'h7a: k3 <= !released; // 3
				8'h6b: if (extended) {k5, shifted} <= {!released, !released}; else k4 <= !released; // 4
				8'h73: k5 <= !released; // 5
				8'h74: if (extended) {k8, shifted} <= {!released, !released}; else k6 <= !released; // 6
				8'h6c: k7 <= !released; // 7
				8'h75: if (extended) {k7, shifted} <= {!released, !released}; else k8 <= !released; // 8
				8'h7d: k9 <= !released; // 9

				
				8'h41:	if (shifted) {kr, kss, special} <= {!released, !released, !released}; // <
								else {kn, kss, special} <= {!released, !released, !released}; // comma
				8'h49: 	if (shifted) {kt, kss, special} <= {!released, !released, !released}; // >
								else {km, kss, special} <= {!released, !released, !released}; // fullstop
				8'h52: 	if (shifted) {kp, kss, special} <= {!released, !released, !released}; // '
								else {k7, kss, special} <= {!released, !released, !released}; // @
				8'h4c: 	if (shifted) {kz, kss, special} <= {!released, !released, !released}; // :
								else {ko, kss, special} <= {!released, !released, !released}; // ;
				8'h4a: 	if (shifted) {kc, kss, special} <= {!released, !released, !released}; // ?
								else {kv, kss, special} <= {!released, !released, !released}; // /
				8'h7c: {kb, kss, special} <= {!released, !released, !released}; // *
				8'h4e: 	if (shifted) {k0, kss, special} <= {!released, !released, !released}; // _
								else {kj, kss, special} <= {!released, !released, !released}; // -
				8'h7b: {kj, kss, special} <= {!released, !released, !released}; // -
				8'h55: 	if (shifted) {kk, kss, special} <= {!released, !released, !released}; // +
								else {kl, kss, special} <= {!released, !released, !released}; // =
				8'h79: {kk, kss} <= {!released, !released}; // +
				8'h0d: {shifted, ksp} <= {!released, !released}; // tab -> break

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

        8'h59: shifted <= !released;
        8'h12: shifted <= !released;
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
      extended <= 1'b0;
    end
  end


endmodule
