using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[CreateAssetMenu]
public class Four_Tone_Palette : ScriptableObject
{
    public Color32 veryLightTone, lightTone, darkTone, veryDarkTone;
    [Range(0, 1)]
    public float ditherSpread;
}
