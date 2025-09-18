package com.liferay.block.oauth.requests;

import com.liferay.portal.kernel.log.Log;
import com.liferay.portal.kernel.log.LogFactoryUtil;
import com.liferay.portal.kernel.servlet.BaseFilter;
import org.osgi.service.component.annotations.Activate;
import org.osgi.service.component.annotations.Component;

import javax.servlet.Filter;
import javax.servlet.FilterChain;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

/**
 * @author Gregory Amerson
 */
@Component(
        immediate = true,
        property = {
                "before-filter=Auto Login Filter",
                "dispatcher=REQUEST",
                "servlet-context-name=",
                "servlet-filter-name=Block Servlet Filter",
                "url-pattern=/o/oauth2/*"
        },
        service = Filter.class
)
public class BlockRequestsFilter extends BaseFilter {

    @Activate
    public void activate() {
        _log.info("Activating BlockRequestFilter");
    }

    @Override
    protected Log getLog() {
        return _log;
    }

    @Override
    protected void processFilter(
            HttpServletRequest httpServletRequest,
            HttpServletResponse httpServletResponse, FilterChain filterChain)
            throws Exception {

        //httpServletResponse.sendError(HttpServletResponse.SC_FORBIDDEN, "xXx Access to this resource is forbidden");
        //httpServletResponse.sendError(HttpServletResponse.SC_BAD_REQUEST, "Bad request; I'm grumpy");
        httpServletResponse.sendError(HttpServletResponse.SC_UNAUTHORIZED, "Unauthorized access to resource");

        processFilter(
                BlockRequestsFilter.class.getName(), httpServletRequest,
                httpServletResponse, filterChain);
    }

    private static final Log _log = LogFactoryUtil.getLog(
            BlockRequestsFilter.class);

}
