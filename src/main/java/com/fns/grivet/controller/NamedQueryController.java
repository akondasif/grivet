/*
 * Copyright 2015 - Chris Phillipson
 * 
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 *
 * You may obtain a copy of the License at
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
package com.fns.grivet.controller;

import org.apache.commons.lang3.StringUtils;
import org.json.JSONArray;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.util.Assert;
import org.springframework.util.MultiValueMap;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.util.UriComponentsBuilder;

import com.fns.grivet.query.NamedQuery;
import com.fns.grivet.query.QueryType;
import com.fns.grivet.service.NamedQueryService;


/**
 * Provides end-points for registration, verification and execution of named queries
 * 
 * @author Chris Phillipson
 */
@RestController
@RequestMapping("/query")
public class NamedQueryController {

    private final NamedQueryService namedQueryService;
    
    @Autowired
    public NamedQueryController(NamedQueryService namedQueryService) {
        this.namedQueryService = namedQueryService;
    }
    
    @RequestMapping(method=RequestMethod.POST, 
            consumes=MediaType.APPLICATION_JSON_VALUE, produces=MediaType.APPLICATION_JSON_VALUE)
    public ResponseEntity<?> create(@RequestBody NamedQuery query) {
        ResponseEntity<?> result = ResponseEntity.unprocessableEntity().build();
        Assert.isTrue(StringUtils.isNotBlank(query.getName()), "Query name must not be null, empty or blank.");
        Assert.notNull(query.getQuery(), "Query string must not be null!");
        Assert.isTrue(isSupportedQuery(query), "Query must start with either CALL or SELECT");
        // check for named parameters; but only if they exist
        if (!query.getParams().isEmpty()) {
            query.getParams().keySet()
                .forEach(k -> Assert.isTrue(query.getQuery().contains(String.format(":%s", k)), String.format("Query must contain named parameter [%s]", k)));
        }
        namedQueryService.create(query);
        UriComponentsBuilder ucb = UriComponentsBuilder.newInstance();
        if (query.getParams().isEmpty()) {
            result = ResponseEntity.created(ucb.path("/query/{name}").buildAndExpand(query.getName()).toUri()).build();
        } else {
            result = ResponseEntity.noContent().build(); 
        }
        return result;
    }
    
    @RequestMapping(value="/{name}", produces=MediaType.APPLICATION_JSON_VALUE)
    public ResponseEntity<?> get(@PathVariable("name") String name, @RequestParam MultiValueMap<String, ?> parameters) {
        return ResponseEntity.ok(namedQueryService.get(name, parameters));
    }
    
    @RequestMapping(value="", produces=MediaType.APPLICATION_JSON_VALUE)
    public ResponseEntity<?> all(@RequestParam("showAll") String showAll) {
        JSONArray payload = namedQueryService.all();
        return ResponseEntity.ok(payload.toString());
    }
    
    private boolean isSupportedQuery(NamedQuery query) {
        boolean result = false;
        if ((query.getQuery().toUpperCase().startsWith("SELECT") && query.getType().equals(QueryType.SELECT)) 
                || (query.getQuery().toUpperCase().startsWith("CALL") && query.getType().equals(QueryType.SPROC))) {
            result = true;
        }
        return result;
    }
}