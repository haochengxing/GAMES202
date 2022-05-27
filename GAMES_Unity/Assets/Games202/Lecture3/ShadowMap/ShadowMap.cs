using UnityEngine;

[ExecuteInEditMode]
public class ShadowMap : MonoBehaviour
{
    private Camera _camera;

    public RenderTexture depthTexture;
    /// <summary>
    /// 光照的角度
    /// </summary>
    public Transform lightTrans;

    private Matrix4x4 sm = new Matrix4x4();

    private const string CameraName = "DepthCamera";

    public Shader shader = null;

    private int ProjectionMatrixId = 0;

    private int DepthTextureId = 0;

    void Start()
    {
        GameObject DepthCamera = GameObject.Find(CameraName);
        if (DepthCamera==null)
        {
            _camera = new GameObject(CameraName).AddComponent<Camera>();
        }
        else
        {
            _camera = DepthCamera.GetComponent<Camera>();
        }

        
        _camera.depth = 2;
        _camera.clearFlags = CameraClearFlags.SolidColor;
        _camera.backgroundColor = new Color(1, 1, 1, 0);

        _camera.aspect = 1;
        _camera.transform.position = transform.position;
        _camera.transform.rotation = transform.rotation;
        _camera.transform.parent = transform;

        _camera.orthographic = true;
        _camera.orthographicSize = 10;

        //投影到平面
        sm.m00 = 0.5f;
        sm.m11 = 0.5f;
        sm.m22 = 0.5f;
        sm.m03 = 0.5f;
        sm.m13 = 0.5f;
        sm.m23 = 0.5f;
        sm.m33 = 1;

        depthTexture = new RenderTexture(1024, 1024, 0);
        depthTexture.wrapMode = TextureWrapMode.Clamp;
        _camera.targetTexture = depthTexture;
        _camera.SetReplacementShader(shader, "RenderType");

        ProjectionMatrixId = Shader.PropertyToID("ProjectionMatrix");
        DepthTextureId = Shader.PropertyToID("DepthTexture");
    }

    void Update()
    {
        Matrix4x4 tm = GL.GetGPUProjectionMatrix(_camera.projectionMatrix, false) * _camera.worldToCameraMatrix;

        tm = sm * tm;

        Shader.SetGlobalMatrix(ProjectionMatrixId, tm);
        Shader.SetGlobalTexture(DepthTextureId, depthTexture);
    }


    private void OnDestroy()
    {
        if (_camera!=null)
        {
            DestroyImmediate(_camera);
            _camera = null;
        }

        if (depthTexture != null)
        {
            depthTexture.Release();
            depthTexture = null;
        }
    }
}
