.PHONY: fmt lint

fmt:
	swiftformat .

lint:
	swiftlint lint --quiet
