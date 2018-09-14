#pragma once

#include "settings.h"

class GpuBinaryFunction;
class GpuUnaryFunction;

// Hybrid (CPU-GPU) graph-cut optimizer. 
//  Uses GPU to compute weights for graph and minimizes graph on CPU.
class HybridGraphCutOptimizer
{
public:
    HybridGraphCutOptimizer();
    ~HybridGraphCutOptimizer();

    void execute(
        const Settings::Level& settings,
        GpuUnaryFunction& unary_fn,
        GpuBinaryFunction& binary_fn,
        const float3& step_size,
        stk::GpuVolume& df
    );

private:
    struct Block
    {
        int3 idx;
        int3 dims;
        int3 offset;
    };

    // Allocates CPU and GPU buffers for the costs
    void allocate_cost_buffers(const dim3& size);

    // Sets the unary cost buffer to all zeros
    void reset_unary_cost();

    // Enqueues the given block to the pipeline queue
    void enqueue_block(const Block& block);

    // Dispatches all queues block
    void dispatch_blocks(
        GpuUnaryFunction& unary_fn,
        GpuBinaryFunction& binary_fn,
        const float3& delta
    );


    stk::VolumeFloat2 _unary_cost;
    stk::GpuVolume _gpu_unary_cost;
    
    stk::VolumeFloat4 _binary_cost_x;
    stk::VolumeFloat4 _binary_cost_y;
    stk::VolumeFloat4 _binary_cost_z;

    stk::GpuVolume _gpu_binary_cost_x;
    stk::GpuVolume _gpu_binary_cost_y;
    stk::GpuVolume _gpu_binary_cost_z;

    // Labels from the minimization
    stk::VolumeUChar _labels;
    stk::GpuVolume _gpu_labels;

    // Blocks awaiting cost computation
    std::deque<Block> _cost_queue;
    // Blocks awaiting minimization
    std::deque<Block> _minimize_queue;

};
