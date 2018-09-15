function IES_INIT()

-- JIT 끄기 키고싶으면 주석처리
print('Just In Time OFF');
jit.off()

-- JIT 추가 Optimizer 로딩
-- print('Enable JIT Optimizer');
-- require("jit.opt").start();
end