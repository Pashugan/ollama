//go:build openbsd

package gpu

import "C"

func CheckVRAM() (int64, error) {
	// GPU not supported.
	return 0, nil
}

func GetGPUInfo() GpuInfo {
	// GPU not supported.
	return GpuInfo{
		Library: "cpu",
		Variant: GetCPUVariant(),
		memInfo: memInfo{
			TotalMemory: 0,
			FreeMemory:  0,
			DeviceCount: 0,
		},
	}
}
