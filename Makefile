# Tinder Token Hook Makefile

# 编译器设置
CC = clang
CFLAGS = -dynamiclib -fobjc-arc -framework Foundation
OUTPUT = TinderTokenHook.dylib
SOURCE = TinderTokenHook.m

# 默认目标
all: $(OUTPUT)

# 编译dylib
$(OUTPUT): $(SOURCE)
	$(CC) $(CFLAGS) -o $(OUTPUT) $(SOURCE)
	@echo "编译完成: $(OUTPUT)"

# 清理
clean:
	rm -f $(OUTPUT)
	@echo "清理完成"

# 安装到设备（需要配置设备IP）
install: $(OUTPUT)
	scp $(OUTPUT) root@<设备IP>:/tmp/
	@echo "已传输到设备 /tmp/ 目录"

# 查看帮助
help:
	@echo "可用命令:"
	@echo "  make        - 编译dylib"
	@echo "  make clean  - 清理编译文件"
	@echo "  make install - 传输到设备（需要配置设备IP）"
	@echo "  make help   - 显示本帮助"

.PHONY: all clean install help