# Main building script

include scripts/make/cargo.mk

ifeq ($(APP_TYPE), c)
  include scripts/make/build_c.mk
else
  rust_package := $(shell cat $(APP)/Cargo.toml | sed -n 's/^name = "\([a-z0-9A-Z_\-]*\)"/\1/p')
  rust_target_dir := $(CURDIR)/target/$(TARGET)/$(MODE)
  rust_elf := $(rust_target_dir)/$(rust_package)
endif

ifneq ($(filter $(MAKECMDGOALS),doc doc_check_missing),)  # run `cargo doc`
  $(if $(V), $(info RUSTDOCFLAGS: "$(RUSTDOCFLAGS)"))
  export RUSTFLAGS
  export RUSTDOCFLAGS
else ifneq ($(filter $(MAKECMDGOALS),unittest unittest_no_fail_fast),)
  # run `make unittest`
  $(if $(V), $(info RUSTFLAGS: "$(RUSTFLAGS)"))
  export RUSTFLAGS
else ifeq ($(filter $(MAKECMDGOALS),defconfig oldconfig clippy),)
  ifneq ($(V),)
    $(info APP: "$(APP)")
    $(info APP_TYPE: "$(APP_TYPE)")
    $(info FEATURES: "$(FEATURES)")
    $(info arceos features: "$(AX_FEAT)")
    $(info lib features: "$(LIB_FEAT)")
    $(info app features: "$(APP_FEAT)")
  endif
  ifeq ($(APP_TYPE), c)
    $(if $(V), $(info CFLAGS: "$(CFLAGS)") $(info LDFLAGS: "$(LDFLAGS)"))
  else ifeq ($(APP_TYPE), rust)
    RUSTFLAGS += $(RUSTFLAGS_LINK_ARGS)
  endif
  $(if $(V), $(info RUSTFLAGS: "$(RUSTFLAGS)"))
  export RUSTFLAGS
endif

_cargo_build: oldconfig
	@printf "    $(GREEN_C)Building$(END_C) App: $(APP_NAME), Arch: $(ARCH), Platform: $(PLAT_NAME), App type: $(APP_TYPE)\n"
ifeq ($(APP_TYPE), rust)
	$(call cargo_build,--manifest-path $(APP)/Cargo.toml,$(AX_FEAT) $(LIB_FEAT) $(APP_FEAT))
	@cp $(rust_elf) $(OUT_ELF)
else ifeq ($(APP_TYPE), c)
	$(call cargo_build,-p axlibc,$(AX_FEAT) $(LIB_FEAT))
endif

$(OUT_DIR):
	$(call run_cmd,mkdir,-p $@)

$(OUT_BIN): _cargo_build $(OUT_ELF)
	$(call run_cmd,$(OBJCOPY),$(OUT_ELF) --strip-all -O binary $@)
	$(call run_cmd,$(OBJDUMP),$(OUT_ELF) --demangle -d > $(OUT_ASM))

.PHONY: _cargo_build
