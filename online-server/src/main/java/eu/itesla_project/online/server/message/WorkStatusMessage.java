/**
 * Copyright (c) 2016, All partners of the iTesla project (http://www.itesla-project.eu/consortium)
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/.
 */
package eu.itesla_project.online.server.message;

import javax.json.stream.JsonGenerator;

import eu.itesla_project.online.WorkSynthesis;

/**
 *
 * @author Quinary <itesla@quinary.com>
 */
public class WorkStatusMessage extends Message<WorkSynthesis> {

    public WorkStatusMessage(WorkSynthesis status) {
        super(status);
    }

    private String type = "workStatus";

    @Override
    protected String getType() {
        return type;
    }

    @Override
    public String toJson() {
        return writeValueAsString(this);
    }

    @Override
    protected void toJson(JsonGenerator generator) {

    }

}
