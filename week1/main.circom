pragma circom 2.1.6;

template CompConstant(ct) {
    signal input in[254];
    signal output out;

    signal parts[127];
    signal sout;

    var clsb;
    var cmsb;
    var slsb;
    var smsb;

    var sum=0;

    var b = (1 << 128) -1;
    var a = 1;
    var e = 1;
    var i;

    for (i=0;i<127; i++) {
        clsb = (ct >> (i*2)) & 1;
        cmsb = (ct >> (i*2+1)) & 1;
        slsb = in[i*2];
        smsb = in[i*2+1];

        if ((cmsb==0)&&(clsb==0)) {
            parts[i] <== -b*smsb*slsb + b*smsb + b*slsb;
        } else if ((cmsb==0)&&(clsb==1)) {
            parts[i] <== a*smsb*slsb - a*slsb + b*smsb - a*smsb + a;
        } else if ((cmsb==1)&&(clsb==0)) {
            parts[i] <== b*smsb*slsb - a*smsb + a;
        } else {
            parts[i] <== -a*smsb*slsb + a;
        }

        sum = sum + parts[i];

        b = b -e;
        a = a +e;
        e = e*2;
    }

    sout <== sum;

    component num2bits = Num2Bits(135);

    num2bits.in <== sout;

    out <== num2bits.out[127];
}

template Num2Bits (nBits) {
    signal input in;
    signal output out[nBits];
    var accum = 0;

    for (var i = 0; i < nBits; i++) {
        out[i] <-- (in >> i) & 1;
        out[i] * (1 - out[i]) === 0;
        accum += (2**i) * out[i];
    }

    accum === in;
}

template IsZero () {
    signal input in;
    signal output out;
    signal inv;

    inv <-- in == 0 ? 0 : 1 / in;

    out <== -in * inv + 1;
    in * out === 0;
}

template IsEqual () {
    signal input in[2];
    signal output out;

    component z = IsZero();
    z.in <== in[0] - in[1];
    out <== z.out;
}

template CalculateTotal(n) {
    signal input in[n];
    signal output out;

    signal mid[n];
    mid[0] <== in[0];

    for (var i = 1; i < n; i++) {
        mid[i] <== mid[i-1] + in[i];
    }

    out <== mid[n-1];
}

template Selector (n) {
    signal input in[n];
    signal input index;
    signal output out;

    component lt = LessThan();
    lt.in <== [index, n];
    lt.out === 1;

    component sum = CalculateTotal(n);
    component eqs[n];
    for (var i = 0; i < n; i++) {
        eqs[i] = IsEqual();
        eqs[i].in <== [index, i];
        sum.in[i] <== eqs[i].out * in[i];
    }

    out <== sum.out;
}

template IntegerDivision(nbits) {
    signal input dividend;
    signal input divisor;
    signal output remainder;
    signal output quotient;

    // Check that divisor is less than dividend

    signal remainders[nbits+1];
    remainders[0] <== dividend;

    component sum = CalculateTotal(nbits);
    component is_neg[nbits];
    for (var i = 0; i < nbits; i++) {
        remainders[i+1] <== (remainders[i] - divisor); // diff and not done

        is_neg[i] = IsNegative();
        is_neg[i].in <== remainders[i+1];

        sum.in[i] <== (is_neg[i].out-1) * -1; // invert to not-negative
    }

    quotient <== sum.out;

    component sel = Selector(nbits);
    for (var i = 0; i < nbits; i++) {
        sel.in[i] <== remainders[i+1];
    }
    sel.index <== quotient-1;
    remainder <== sel.out;
}

template Or () {
    signal input in[2];
    signal output out;

    //var inv = 1 / (in[0] + in[1]);
    // Unsafely assuming ins are 1 or 0
    //1 === inv * (in[0] + in[1]);

    component iz = IsZero();
    iz.in <== in[0] + in[1];
    out <== (iz.out - 1) * -1; // not zero
    //out <== inv * (in[0] + in[1]);
}

template IsNegative () {
    signal input in;
    signal output out;

    component nb = Num2Bits(254);
    nb.in <== in;

    component lt = CompConstant(10944121435919637611123202872628637544274182200208017171849102093287904247808);
    lt.in <== nb.out;
    out <== lt.out;
}

template LessThan() {
    signal input in[2];
    signal output out;

    signal diff <== in[0] - in[1];
    component isneg = IsNegative();
    isneg.in <== diff;

    out <== isneg.out;
}

//component main = Num2Bits(4);
//component main = IsZero();
//component main = IsEqual();
//component main = Selector(3);
//component main = IsNegative();
//component main = LessThan();
//component main = CalculateTotal(3);
component main = IntegerDivision(126);
//component main = Or();

/* INPUT = {
    "dividend": "21",
    "divisor": "5"
} */

