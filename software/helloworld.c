#include "xparameters.h"
#include "xaxivdma.h"
#include "xil_printf.h"

XAxiVdma Vdma;

int main() {
    int Status;
    XAxiVdma_Config *Config;
    XAxiVdma_DmaSetup ReadCfg;
    XAxiVdma_DmaSetup WriteCfg;

    xil_printf("Starting Final VDMA Initialization...\r\n");

    Config = XAxiVdma_LookupConfig(XPAR_XAXIVDMA_0_BASEADDR);
    Status = XAxiVdma_CfgInitialize(&Vdma, Config, Config->BaseAddress);

    // --- HARD VDMA RESET ---
    // This cures the "requires a full reprogramming" bug
    XAxiVdma_Reset(&Vdma, XAXIVDMA_WRITE);
    XAxiVdma_Reset(&Vdma, XAXIVDMA_READ);
    while(XAxiVdma_ResetNotDone(&Vdma, XAXIVDMA_WRITE)) {}
    while(XAxiVdma_ResetNotDone(&Vdma, XAXIVDMA_READ)) {}
    xil_printf("VDMA Reset Complete.\r\n");

    u32 FrameSize = 640 * 480 * 4; 
    u32 FrameStoreStart = XPAR_MIG_0_BASEADDRESS + 0x01000000; 
    
    UINTPTR BufferAddrs[3];
    for (int i = 0; i < 3; i++) {
        BufferAddrs[i] = FrameStoreStart + (i * FrameSize);
    }

    // --- WRITE CHANNEL (Camera to DDR) ---
    WriteCfg.VertSizeInput = 480;      
    WriteCfg.HoriSizeInput = 640 * 4;  
    WriteCfg.Stride = 640 * 4;         
    WriteCfg.FrameDelay = 0;           
    WriteCfg.EnableCircularBuf = 1;    
    WriteCfg.EnableSync = 0;           // <--- GENLOCK DISABLED. Never halt.
    WriteCfg.PointNum = 0;             
    WriteCfg.EnableFrameCounter = 0;   
    WriteCfg.FixedFrameStoreAddr = 0;  

    Status = XAxiVdma_DmaConfig(&Vdma, XAXIVDMA_WRITE, &WriteCfg);
    Status = XAxiVdma_DmaSetBufferAddr(&Vdma, XAXIVDMA_WRITE, BufferAddrs);

    // --- READ CHANNEL (DDR to Monitor) ---
    ReadCfg.VertSizeInput = 480;      
    ReadCfg.HoriSizeInput = 640 * 4;  
    ReadCfg.Stride = 640 * 4;         
    ReadCfg.FrameDelay = 0;           
    ReadCfg.EnableCircularBuf = 1;    
    ReadCfg.EnableSync = 0;           // <--- GENLOCK DISABLED. Never halt.
    ReadCfg.PointNum = 0;             
    ReadCfg.EnableFrameCounter = 0;   
    ReadCfg.FixedFrameStoreAddr = 0;  

    Status = XAxiVdma_DmaConfig(&Vdma, XAXIVDMA_READ, &ReadCfg);
    Status = XAxiVdma_DmaSetBufferAddr(&Vdma, XAXIVDMA_READ, BufferAddrs);

    // Apply "Flush on Fsync" armor to the Write Channel
    u32 S2mmCr = Xil_In32(Config->BaseAddress + 0x30);
    Xil_Out32(Config->BaseAddress + 0x30, S2mmCr | 0x00000002);

    // START ENGINES
    Status = XAxiVdma_DmaStart(&Vdma, XAXIVDMA_WRITE);
    Status = XAxiVdma_DmaStart(&Vdma, XAXIVDMA_READ);

    xil_printf("VDMA Engines Running. Video Out IP should now lock and output!\r\n");

    while (1) {}
    return 0;
}