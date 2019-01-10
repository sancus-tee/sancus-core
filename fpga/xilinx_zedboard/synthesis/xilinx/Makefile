VIVADO  = vivado
RM      = rm -f

all: build

build:
	$(VIVADO) -mode batch -source scripts/build.tcl

implement:
	$(VIVADO) -mode batch -source scripts/implement.tcl

program:
	$(VIVADO) -mode batch -source scripts/program.tcl

clean:
	$(RM) -r .Xil/
	$(RM) *.log *.jou
