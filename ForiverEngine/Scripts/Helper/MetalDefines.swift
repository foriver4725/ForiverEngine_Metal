import Metal
import simd

// 頂点データ（ブロック）
struct VertexData {
    var position: Vector4  // モデル座標系
    var uv: Vector2  // 左上が原点
    var normal: Vector3  // 法線ベクトル
    var centerWorldPosition: Vector3  // モデル中心のワールド座標
    var textureIndex: UInt32  // 使用するテクスチャのインデックス
}

// 頂点データ（板ポリ）
struct VertexDataQuad {
    var position: Vector4  // 画面座標系 [-1, 1]
    var uv: Vector2  // 左上が原点
}

// 頂点レイアウト単品
struct VertexLayout {
    let format: MTLVertexFormat
}

// 頂点レイアウト（ブロック）
let VertexLayouts: [VertexLayout] = [
    VertexLayout(format: .float4),
    VertexLayout(format: .float2),
    VertexLayout(format: .float3),
    VertexLayout(format: .float3),
    VertexLayout(format: .uint),
]

// 頂点レイアウト（板ポリ）
let VertexLayoutsQuad: [VertexLayout] = [
    VertexLayout(format: .float4),
    VertexLayout(format: .float2),
]
