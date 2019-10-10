#include "landmarks.h"

#include "cost_function_kernel.h"

namespace cuda = stk::cuda;

template<typename T>
struct LandmarksImpl
{
    typedef T VoxelType;

    LandmarksImpl(
        float3 origin,
        float3 spacing,
        Matrix3x3f direction,
        const thrust::device_vector<float3>& landmarks,
        const thrust::device_vector<float3>& displacements,
        float half_decay
    ) :
        _origin(origin),
        _spacing(spacing),
        _direction(direction),
        _landmarks(thrust::raw_pointer_cast(landmarks.data())),
        _displacements(thrust::raw_pointer_cast(displacements.data())),
        _landmark_count(landmarks.size()),
        _half_decay(half_decay)
    {
    }

    __device__ float operator()(
        const cuda::VolumePtr<VoxelType>& fixed,
        const cuda::VolumePtr<VoxelType>& moving,
        const dim3& fixed_dims,
        const dim3& moving_dims,
        const int3& fixed_p,
        const float3& moving_p,
        const float3& d
    )
    {
        const float epsilon = 1e-6f;

        float3 xyz = float3{float(fixed_p.x),float(fixed_p.y),float(fixed_p.z)};
        float3 world_p = _origin + _direction * (xyz * _spacing);

        float c = 0;
        for (size_t i = 0; i < _landmark_count; ++i) {
            const float inv_den = 1.0f 
                / (pow(stk::norm2(_landmarks[i] - world_p), _half_decay) + epsilon);
            c += stk::norm2(d - _displacements[i]) * inv_den;
        }
        return c;
    }

    float3 _origin;
    float3 _spacing;
    Matrix3x3f _direction;

    const float3 * const __restrict _landmarks;
    const float3 * const __restrict _displacements;
    const size_t _landmark_count;

    const float _half_decay;
};

void GpuCostFunction_Landmarks::cost(
    stk::GpuVolume& df,
    const float3& delta,
    float weight,
    const int3& offset,
    const int3& dims,
    stk::GpuVolume& cost_acc,
    Settings::UpdateRule update_rule,
    stk::cuda::Stream& stream
)
{
    ASSERT(df.usage() == stk::gpu::Usage_PitchedPointer);
    ASSERT(cost_acc.voxel_type() == stk::Type_Float2);

    // <float> isn't really necessary but it is required by CostFunctionKernel
    auto kernel = CostFunctionKernel<LandmarksImpl<float>>(
        LandmarksImpl<float>(
            _origin,
            _spacing,
            _direction,
            _landmarks,
            _displacements,
            _half_decay
        ),
        stk::GpuVolume(),
        stk::GpuVolume(),
        _fixed_mask,
        _moving_mask,
        df,
        weight,
        cost_acc
    );

    invoke_cost_function_kernel(kernel, delta, offset, dims, update_rule, stream);
}


