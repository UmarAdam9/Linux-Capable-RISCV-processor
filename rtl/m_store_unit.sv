

//Umar Adam: this module outputs the store_ops to the dbus
module m_store_unit(
  input       [2:0] func3,
  input       [1:0] dmem_address,
  output reg  [3:0] byte_en,
  output reg  [1:0] st_ops // Store operation type
);

//=======================================================
//  Structural coding
//=======================================================
  always@(*)
  begin
    case(func3)
      // sb (store byte)
      3'd0 : begin
        case(dmem_address)
          2'd0    : byte_en = 4'b0001;
          2'd1    : byte_en = 4'b0010;
          2'd2    : byte_en = 4'b0100;
          2'd3    : byte_en = 4'b1000;
          default : byte_en = 4'b0001;
        endcase
        st_ops = 2'b00; // Byte store
      end
      // sh (store halfword)
      3'd1 : begin
        case(dmem_address)
          2'd0    : byte_en = 4'b0011;
          2'd2    : byte_en = 4'b1100;
          default : byte_en = 4'b0011;
        endcase
        st_ops = 2'b01; // Halfword store
      end
      // sw (store word)
      3'd2 : begin
        byte_en = 4'b1111;
        st_ops = 2'b10; // Word store
      end
      // Default case: No store operation
      default : begin
        byte_en = 4'b0000;
        st_ops = 2'b11; // None
      end
    endcase
  end

endmodule
