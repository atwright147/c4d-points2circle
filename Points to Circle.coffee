/* **************************************************
PointstoCircle
DavidWickenden2007
*************************************************** */

main(doc, op)
{
    var radius = 50; // Enter radius value here.

    if (!doc -> GetActiveObject()) return;
    if (!instanceof(op, PolygonObject)) return;

    var bc = new(BaseContainer);
    bc -> SetData(MDATA_CONVERTSELECTION_LEFT, 0);
    bc -> SetData(MDATA_CONVERTSELECTION_RIGHT, 1);

    SendModelingCommand(MCOMMAND_CONVERTSELECTION, doc, op, bc, MODIFY_POINTSELECTION);
    SendModelingCommand(MCOMMAND_EDGE_TO_SPLINE, doc, op, bc, MODIFY_EDGESELECTION);

    if (!op -> GetDown()) return;
    if (op -> GetDown() -> GetType() ! = OBJECT_SPLINE) return;

    var pointCnt = op -> GetPointCount();
    var pointSel = op -> GetPointSelection();
    var pointSelCnt = pointSel -> GetCount();

    var spline = op -> GetDown();
    var spPointCnt = spline -> GetPointCount();
    var spPointSel = spline -> GetPointSelection();
    var spPointSelCnt = spPointSel -> GetCount();

    if (spPointCnt! = pointSelCnt) return;

    var arr = new(array, pointCnt, 2);

    var i, j, k = 0;
    var found = 0;

    for(i = 0; i < pointCnt; i++)
    {
        if (found> = pointSelCnt) break;
        if (pointSel -> IsSelected(i))
        {
            for(j = 0; j < spPointCnt; j++)
            {
                if (op -> GetPoint(i) == spline -> GetPoint(j))
                {
                    arr[k][0] = i;
                    arr[k][1] = j;
                }
            }
            k++;
            found++;
        }
    }

    var vectorSum = vector(0, 0, 0);
    var found = 0;

    for(i = 0; i < spPointCnt; i++)
    {
        vectorSum += spline -> GetPoint(i);
    }

    var mSp = spline -> GetMg();
    var vectorAv = vectorSum / spPointCnt;
    var vectorAv_g = mSp -> GetMulP(vectorAv);
    var refPointA = spline -> GetPoint(0);
    var refPointB = spline -> GetPoint(1);
    var refPointAg = mSp -> GetMulP(refPointA);
    var refPointBg = mSp -> GetMulP(refPointB);

    var m = new(Matrix);

    m -> SetV0(vectorAv_g);
    m -> SetV1(vnorm(refPointAg - vectorAv_g));
    var mV1 = m -> GetV1();
    m -> SetV3(vnorm(vcross(mV1, (refPointBg - vectorAv_g))));
    var mV3 = m -> GetV3();
    m -> SetV2(vnorm(vcross(mV3, mV1)));

    var angle = 6.283 / spPointCnt;
    var mOp = op -> GetMg();
    var k;

    for(k = 0;k<pointSelCnt;k++)
    {
        var pointA = spline -> GetPoint(arr[k][1]);
        var pointAg = mSp -> GetMulP(pointA);

        m -> Invert();
        var pointAl = m -> GetMulP(pointAg);
        var posAl_x = cos(angle * (arr[k][1])) * radius;
        var posAl_y = sin(angle * (arr[k][1])) * radius;
        var pointAlMod = vector(posAl_x, posAl_y, pointAl.z);

        m -> Invert();
        var pointAg2 = m -> GetMulP(pointAlMod);

        mOp -> Invert();
        var pointAl2 = mOp -> GetMulP(pointAg2);

        op -> SetPoint(arr[k][0], pointAl2);
        mOp -> Invert();
    }

    spline -> Remove();
    op -> Message(MSG_UPDATE);
}
