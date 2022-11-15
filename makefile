all:
	# Assemble our loader and relocator (which embeds the loader)
	pasmo loader.asm loader.bin
	pasmo relocate.asm relocate.bin

	# Embed relocator in REM loader
	bin2bas -ftap="E L I T E" relocate.bin loader.tap

	# Convert dumped binary file to tap
	bin2tap -o $(TARGET)_bin.tap $(TARGET).bin

	# Merge everything into one tap
	tzxmerge -o $(TARGET)_combined.tap loader.tap $(TARGET)_bin.tap

	# Remove the superfluous headers
	tzxcut -i $(TARGET)_combined.tap -o $(TARGET).tap --invert 2

	# Clean up interim files
	rm relocate.bin
	rm loader.bin
	rm loader.tap
	rm $(TARGET)_bin.tap
	rm $(TARGET)_combined.tap

both:
	make TARGET=elite48_a
	make TARGET=elite48_b
