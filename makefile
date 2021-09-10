all:
	# Assemble our loader and relocator (which embeds the loader)
	pasmo loader.asm loader.bin
	pasmo relocate.asm relocate.bin

	# Embed relocator in REM loader
	bin2bas -ftzx="E L I T E" relocate.bin loader.tzx

	# Convert dumped binary file to tap
	bin2tap -o $(TARGET)_bin.tap $(TARGET).bin

	# Convert taps to tzx for easier handling
	tap2tzx $(TARGET)_bin.tap

	# Merge everything into one tzx
	tzxmerge -o $(TARGET)_combined.tzx loader.tzx $(TARGET)_bin.tzx

	# Remove the superfluous headers
	tzxcut -i $(TARGET)_combined.tzx -o $(TARGET).tzx --invert 2

	# Convert that tzx to a tap
	tzx2tap $(TARGET).tzx

	# Clean up interim files
	rm relocate.bin
	rm loader.bin
	rm loader.tzx
	rm $(TARGET)_bin.tap
	rm $(TARGET)_bin.tzx
	rm $(TARGET)_combined.tzx
	rm $(TARGET).tzx

both:
	make TARGET=elite48_a
	make TARGET=elite48_b
