//////////////////////////////////////////////////////////////////////////
/// Author (name and email): Qazi Hamid Ullah, qullah.bee20seecs@seecs.edu.pk
/// Date Created: 2/24/2024
///////////////////////////////////////////////////////////////////////////

module load_unit
(
  input      [31:0] data_in_load,
  input      [ 2:0] func3,
  input      [ 1:0] addr,
  output reg [31:0] data_out_load
);

//=======================================================
//  Structural coding
//=======================================================

  always@(*)
  begin
    case(func3)
      //lb
      3'd0    : begin
        case(addr)
          2'd0    : data_out_load <= {{24{data_in_load[7 ]}}, data_in_load[ 7: 0]};
          2'd1    : data_out_load <= {{24{data_in_load[15]}}, data_in_load[15: 8]};
          2'd2    : data_out_load <= {{24{data_in_load[23]}}, data_in_load[23:16]};
          2'd3    : data_out_load <= {{24{data_in_load[31]}}, data_in_load[31:24]};
          default : data_out_load <= {{24{data_in_load[7 ]}}, data_in_load[ 7: 0]};
        endcase
      end
      //lh
      3'd1    : begin
        case(addr)
          2'd0    : data_out_load <= {{16{data_in_load[15]}}, data_in_load[15: 0]};
          2'd2    : data_out_load <= {{16{data_in_load[31]}}, data_in_load[31:16]};
          default : data_out_load <= {{16{data_in_load[15]}}, data_in_load[15: 0]};
        endcase
      end
      //lw
      3'd2    : data_out_load <= data_in_load;

      //lbu
      3'd4    : begin
        case(addr)
          2'd0    : data_out_load <= {24'b0, data_in_load[ 7: 0]};
          2'd1    : data_out_load <= {24'b0, data_in_load[15: 8]};
          2'd2    : data_out_load <= {24'b0, data_in_load[23:16]};
          2'd3    : data_out_load <= {24'b0, data_in_load[31:24]};
          default : data_out_load <= {24'b0, data_in_load[ 7: 0]};
        endcase
      end
      //lhu
      3'd5    : begin
        case(addr)
          2'd0    : data_out_load <= {16'b0, data_in_load[15: 0]};
          2'd2    : data_out_load <= {16'b0, data_in_load[31:16]};
          default : data_out_load <= {16'b0, data_in_load[15: 0]};
        endcase
      end
      default : data_out_load <= data_in_load;
    endcase
  end

endmodule
