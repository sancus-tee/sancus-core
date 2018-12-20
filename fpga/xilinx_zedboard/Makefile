VIVADO  = vivado
RM      = rm -f

all: build

build:
	$(VIVADO) -mode batch -source vivado/build.tcl

implement:
	$(VIVADO) -mode batch -source vivado/implement.tcl

program:
	$(VIVADO) -mode batch -source vivado/program.tcl

clean:
	$(RM) -r .Xil/
	$(RM) *.log *.jou
