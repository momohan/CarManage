package com.system.action.base;

import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.OutputStream;
import java.lang.reflect.Method;
import java.lang.reflect.ParameterizedType;
import java.text.SimpleDateFormat;
import java.util.Arrays;
import java.util.Date;
import java.util.List;
import java.util.Map;
import java.util.UUID;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

import org.apache.commons.lang3.StringUtils;
import org.apache.commons.lang3.reflect.FieldUtils;
import org.apache.geronimo.mail.util.Base64;
import org.apache.log4j.Logger;
import org.apache.poi.ss.formula.functions.T;
import org.apache.struts2.ServletActionContext;
import org.apache.struts2.convention.annotation.Action;
import org.apache.struts2.convention.annotation.Namespace;
import org.apache.struts2.convention.annotation.ParentPackage;

import com.alibaba.fastjson.JSON;
import com.alibaba.fastjson.serializer.SerializerFeature;
import com.framework.util.BeanUtils;
import com.framework.util.FastjsonFilter;
import com.framework.util.HqlFilter;
import com.opensymphony.xwork2.ActionSupport;
import com.system.entity.easyui.Grid;
import com.system.entity.easyui.Json;
import com.system.service.base.BaseServiceI;

/**
 * 基础ACTION,其他ACTION继承此ACTION来获得writeJson和ActionSupport的功能
 * 
 * 基本的CRUD已实现，子类继承BaseAction的时候，提供setService方法即可
 * 
 * 注解@Action后，访问地址就是命名空间+类名(全小写，并且不包括Action后缀)，本action的访问地址就是/base.sy
 * 
 * @author 陈晓亮
 * 
 */
@ParentPackage("SysPackage")
@Namespace("/")
@Action
public class BaseAction<T> extends ActionSupport {
	private static final Logger logger = Logger.getLogger(BaseAction.class);

	protected int page = 1;// 当前页
	protected int rows = 20;// 每页显示记录数
	protected String sort;// 排序字段
	protected String order = "asc";// asc/desc
	protected String q;// easyui的combo和其子类过滤时使用

	protected String id;// 主键
	protected String ids;// 主键集合，逗号分割

	protected BaseServiceI<T> service;// 业务逻辑
	public static Date date = new Date();
	public SimpleDateFormat sdf = new SimpleDateFormat("yyyyMMdd");
	public static boolean locked = false;

	/**生成流水号
	 * @param column 类属性名
	 * @return
	 */
	public String getNumber(String column) {
		String result = null;
		if (locked) {
			return null;
		}
		locked = true;
		try {
			if (sdf.format(date).equals(sdf.format(new Date()))) {
				String className = ((Class<T>) ((ParameterizedType) getClass().getGenericSuperclass()).getActualTypeArguments()[0])
						.getSimpleName();
				System.out.println(className);
				HqlFilter hqlFilter = new HqlFilter();
				hqlFilter.addFilter("QUERY_t#" + column + "_S_RLK", sdf.format(date));
				hqlFilter.addSort(column);
				hqlFilter.addOrder("desc");
				List<T> list =  service.findByFilter(hqlFilter);
				if (list.size()!=0) {
					String attr=(String) getFieldValueByName(column,list.get(0));
					long value = Long.valueOf(attr);
					result = value + 1 + "";
				} else {
					result = sdf.format(date) + "000001";
				}
			} else {
				date = new Date();
				result = sdf.format(date) + "000001";
			}
			locked = false;

		} catch (Exception e) {
			// TODO: handle exception
			e.printStackTrace();
			locked = false;
		}
		return result;

	}
	
	 private Object getFieldValueByName(String fieldName, Object o) {  
	       try {    
	           String firstLetter = fieldName.substring(0, 1).toUpperCase();    
	           String getter = "get" + firstLetter + fieldName.substring(1);    
	           Method method = o.getClass().getMethod(getter, new Class[] {});    
	           Object value = method.invoke(o, new Object[] {});    
	           return value;    
	       } catch (Exception e) {    
	    	   
	           return "";    
	       }    
	   }   

	/**
	 * 继承BaseAction的action需要先设置这个方法，使其获得当前action的业务服务
	 * 
	 * @param service
	 */
	public void setService(BaseServiceI<T> service) {
		this.service = service;
	}

	public String getId() {
		return id;
	}

	public void setId(String id) {
		this.id = id;
	}

	public String getIds() {
		return ids;
	}

	public void setIds(String ids) {
		this.ids = ids;
	}

	public int getPage() {
		return page;
	}

	public void setPage(int page) {
		this.page = page;
	}

	public int getRows() {
		return rows;
	}

	public void setRows(int rows) {
		this.rows = rows;
	}

	public String getSort() {
		return sort;
	}

	public void setSort(String sort) {
		this.sort = sort;
	}

	public String getOrder() {
		return order;
	}

	public void setOrder(String order) {
		this.order = order;
	}

	public String getQ() {
		return q;
	}

	public void setQ(String q) {
		this.q = q;
	}

	/**
	 * 将对象转换成JSON字符串，并响应回前台
	 * 
	 * @param object
	 * @param includesProperties
	 *            需要转换的属性
	 * @param excludesProperties
	 *            不需要转换的属性
	 */
	public void writeJsonByFilter(Object object, String[] includesProperties, String[] excludesProperties) {
		try {
			FastjsonFilter filter = new FastjsonFilter();// excludes优先于includes
			if (excludesProperties != null && excludesProperties.length > 0) {
				filter.getExcludes().addAll(Arrays.<String> asList(excludesProperties));
			}
			if (includesProperties != null && includesProperties.length > 0) {
				filter.getIncludes().addAll(Arrays.<String> asList(includesProperties));
			}
			logger.info("对象转JSON：要排除的属性[" + excludesProperties + "]要包含的属性[" + includesProperties + "]");
			String json;
			String User_Agent = getRequest().getHeader("User-Agent");
			if (StringUtils.indexOfIgnoreCase(User_Agent, "MSIE 6") > -1) {
				// 使用SerializerFeature.BrowserCompatible特性会把所有的中文都会序列化为\\uXXXX这种格式，字节数会多一些，但是能兼容IE6
				json = JSON.toJSONString(object, filter, SerializerFeature.WriteDateUseDateFormat,
						SerializerFeature.DisableCircularReferenceDetect, SerializerFeature.BrowserCompatible);
			} else {
				// 使用SerializerFeature.WriteDateUseDateFormat特性来序列化日期格式的类型为yyyy-MM-dd
				// hh24:mi:ss
				// 使用SerializerFeature.DisableCircularReferenceDetect特性关闭引用检测和生成
				json = JSON.toJSONString(object, filter, SerializerFeature.WriteDateUseDateFormat,
						SerializerFeature.DisableCircularReferenceDetect);
			}
			logger.info("转换后的JSON字符串：" + json);
			getResponse().setContentType("text/html;charset=utf-8");
			getResponse().getWriter().write(json);
			getResponse().getWriter().flush();
			getResponse().getWriter().close();
		} catch (IOException e) {
			e.printStackTrace();
		}
	}

	public void writeText(String result) {
		try {
			logger.info("返回给前台的字符串：" + result);
			getResponse().setContentType("textml;charset=utf-8");
			getResponse().getWriter().write(result);
			getResponse().getWriter().flush();
			getResponse().getWriter().close();
		} catch (Exception e) {
			e.printStackTrace();
		}

	}

	/**
	 * 将对象转换成JSON字符串，并响应回前台
	 * 
	 * @param object
	 * @throws IOException
	 */
	public void writeJson(Object object) {
		writeJsonByFilter(object, null, null);
	}

	/**
	 * 将对象转换成JSON字符串，并响应回前台
	 * 
	 * @param object
	 * @param includesProperties
	 *            需要转换的属性
	 */
	public void writeJsonByIncludesProperties(Object object, String[] includesProperties) {
		writeJsonByFilter(object, includesProperties, null);
	}

	/**
	 * 将对象转换成JSON字符串，并响应回前台
	 * 
	 * @param object
	 * @param excludesProperties
	 *            不需要转换的属性
	 */
	public void writeJsonByExcludesProperties(Object object, String[] excludesProperties) {
		writeJsonByFilter(object, null, excludesProperties);
	}

	/**
	 * 获得request
	 * 
	 * @return
	 */
	public HttpServletRequest getRequest() {
		return ServletActionContext.getRequest();
	}

	/**
	 * 获得response
	 * 
	 * @return
	 */
	public HttpServletResponse getResponse() {
		return ServletActionContext.getResponse();
	}

	/**
	 * 获得session
	 * 
	 * @return
	 */
	public HttpSession getSession() {
		// 给session设置过期前最大保留时间
		HttpSession session = ServletActionContext.getRequest().getSession();
		session.setMaxInactiveInterval(60 * 60);// 设置过期时长1小时
		// return ServletActionContext.getRequest().getSession();
		return session;
	}

	/**
	 * 获得一个对象
	 */
	public void getById() {
		if (!StringUtils.isBlank(id)) {
			writeJson(service.getById(id));
		} else {
			Json j = new Json();
			j.setMsg("主键不可为空！");
			writeJson(j);
		}
	}

	/**
	 * 查找一批对象
	 */
	public void doNotNeedSecurity_find() {
		HqlFilter hqlFilter = new HqlFilter(getRequest());
		writeJson(service.findByFilter(hqlFilter, page, rows));
	}

	/**
	 * 查找所有对象
	 */
	public void doNotNeedSecurity_findAll() {
		HqlFilter hqlFilter = new HqlFilter(getRequest());
		writeJson(service.findByFilter(hqlFilter));
	}

	/**
	 * 查找分页后的grid
	 */
	public void grid() {
		Grid grid = new Grid();
		HqlFilter hqlFilter = new HqlFilter(getRequest());
		grid.setTotal(service.countByFilter(hqlFilter));
		grid.setRows(service.findByFilter(hqlFilter, page, rows));
		writeJson(grid);
	}

	/**
	 * 查找grid所有数据，不分页
	 */
	public void gridAll() {
		Grid grid = new Grid();
		HqlFilter hqlFilter = new HqlFilter(getRequest());
		List<T> l = service.findByFilter(hqlFilter);
		grid.setTotal((long) l.size());
		grid.setRows(l);
		writeJson(grid);
	}

	/**
	 * 获得treeGrid，treeGrid由于提供了pid的扩展，所以不分页
	 */
	public void treeGrid() {
		HqlFilter hqlFilter = new HqlFilter(getRequest());
		writeJson(service.findByFilter(hqlFilter));
	}

	/**
	 * 删除一个对象
	 */
	public void delete() {
		Json json = new Json();
		if (!StringUtils.isBlank(id)) {
			T t = service.getById(id);
			service.delete(t);
			json.setSuccess(true);
			json.setMsg("删除成功！");
		}
		writeJson(json);
	}
	// 存储图片
		public String getFileName(String type,String filestr) {
			String targetDirectory = "";
			String filename = "";
	
			try {
				if (filestr.length() > 0) {
					filename = UUID.randomUUID().toString() + ".jpg";
					targetDirectory =  ServletActionContext.getServletContext().getRealPath("/uploadFile/images/"+type+"/");
					File filedir = new File(targetDirectory);
					if (!filedir.exists()) {
						System.out.println("------文件夹不存在");
						filedir.mkdirs();
					}
					File file = new File(targetDirectory, filename);
					byte[] bytes = Base64.decode(filestr);
					OutputStream out = new FileOutputStream(file);
					out.write(bytes, 0, bytes.length);
					out.close();
				}
			} catch (Exception e) {
				e.printStackTrace();
			}
		
			return "/uploadFile/images/" +type+"/"+ filename;
		}
}