package com.fns.grivet.controller;

import java.lang.reflect.Method;

import org.aspectj.lang.ProceedingJoinPoint;
import org.aspectj.lang.annotation.Around;
import org.aspectj.lang.annotation.Aspect;
import org.aspectj.lang.reflect.MethodSignature;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;

import com.codahale.metrics.MetricRegistry;
import com.codahale.metrics.Timer;

@Aspect
@Component
class MetricsAspect {

	private static final String POINTCUT = "execution(* com.fns.grivet.controller.*Controller.*(..)) && "
			+ "@annotation(org.springframework.web.bind.annotation.RequestMapping)";

	private final MetricRegistry metricRegistry;

	@Autowired
	public MetricsAspect(MetricRegistry metricRegistry) {
		this.metricRegistry = metricRegistry;
	}

	@Around(value = POINTCUT)
	public Object processingTime(ProceedingJoinPoint joinPoint) throws Throwable {
		Class<?> curClass = joinPoint.getTarget().getClass();
		MethodSignature ms = (MethodSignature) joinPoint.getSignature();
		Method method = ms.getMethod();
		Timer timer = metricRegistry.timer(MetricRegistry.name(curClass, method.getName()));
		try (Timer.Context context = timer.time()) {
			return joinPoint.proceed();
		}
	}

}
