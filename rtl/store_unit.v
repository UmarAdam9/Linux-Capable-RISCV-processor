//////////////////////////////////////////////////////////////////////////
/// Author (name and email): Qazi Hamid Ullah, qullah.bee20seecs@seecs.edu.pk
/// Date Created: 2/24/2024
///////////////////////////////////////////////////////////////////////////

module store_unit(
  input       [2:0] func3,
  input       [1:0] dmem_address,
  output reg  [3:0] byte_en
);

//=======================================================
//  Structural coding
//=======================================================
  always@(*)
  begin
    case(func3)
      //sb
      3'd0 : begin
        case(dmem_address)
          2'd0    : byte_en = 4'b0001;
          2'd1    : byte_en = 4'b0010;
          2'd2    : byte_en = 4'b0100;
          2'd3    : byte_en = 4'b1000;
          default : byte_en = 4'b0001;
        endcase
      end
      //sh
      3'd1 : begin
        case(dmem_address)
          2'd0    : byte_en = 4'b0011;
          2'd2    : byte_en = 4'b1100;
          default : byte_en = 4'b0011;
        endcase
      end
      //sw
      3'd2 : byte_en = 4'b1111;

      default : byte_en = 4'b1111;
    endcase
  end

endmodule
